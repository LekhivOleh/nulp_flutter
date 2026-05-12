using System.Data;
using Microsoft.Data.Sqlite;
using NulpAccessApi.Models;

namespace NulpAccessApi.Services;

public interface IDataService
{
    Task<AppUser?> GetUserByEmail(string email);
    Task<AppUser?> GetUserById(string id);
    Task<AppUser> RegisterUser(RegisterRequest req);
    Task<List<AccessLog>> GetLogs();
    Task AddLog(AccessLog log);
    Task MakeUserAdmin(string userId, string adminRequesterId);
    Task<List<RfidCardEntry>> GetRegisteredCards();
    Task RegisterCard(string cardId, string userId);
}

public class DataService : IDataService
{
    private readonly string _dbPath;

    public DataService()
    {
        _dbPath = Path.Combine(Directory.GetCurrentDirectory(), "backend.db");
        EnsureDatabase();
        EnsureInitialAdmin().GetAwaiter().GetResult();
    }

    private static string NormalizeCardId(string cardId)
    {
        return cardId?.Replace(":", "").ToUpperInvariant() ?? "";
    }

    private void EnsureDatabase()
    {
        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        conn.Open();

        var cmd = conn.CreateCommand();
        cmd.CommandText = @"
            CREATE TABLE IF NOT EXISTS Users(
                Id TEXT PRIMARY KEY,
                Name TEXT NOT NULL,
                Email TEXT NOT NULL UNIQUE,
                Password TEXT NOT NULL,
                IsAdmin INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS Logs(
                Uid TEXT PRIMARY KEY,
                UserId TEXT,
                Name TEXT,
                Direction TEXT,
                Timestamp TEXT,
                CardId TEXT
            );

            CREATE TABLE IF NOT EXISTS RfidCards(
                CardId TEXT PRIMARY KEY,
                UserId TEXT NOT NULL,
                FOREIGN KEY(UserId) REFERENCES Users(Id)
            );
        ";
        cmd.ExecuteNonQuery();
    }

    private async Task EnsureInitialAdmin()
    {
        var existing = await GetUserByEmail("oleh@oleh.com");
        if (existing == null)
        {
            var req = new RegisterRequest { Name = "oleh", Email = "oleh@oleh.com", Password = "123123" };
            var user = await RegisterUser(req);

            using var conn = new SqliteConnection($"Data Source={_dbPath}");
            await conn.OpenAsync();
            var upd = conn.CreateCommand();
            upd.CommandText = "UPDATE Users SET IsAdmin = 1 WHERE Id = $id";
            upd.Parameters.AddWithValue("$id", user.Id);
            await upd.ExecuteNonQueryAsync();

            await RegisterCard("63437C28", user.Id);
        }
    }

    public async Task<AppUser?> GetUserByEmail(string email)
    {
        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        await conn.OpenAsync();
        var cmd = conn.CreateCommand();
        cmd.CommandText = "SELECT Id, Name, Email, Password, IsAdmin FROM Users WHERE Email = $email";
        cmd.Parameters.AddWithValue("$email", email);
        using var reader = await cmd.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return new AppUser
            {
                Id = reader.GetString(0),
                Name = reader.GetString(1),
                Email = reader.GetString(2),
                Password = reader.GetString(3),
                IsAdmin = reader.GetInt32(4) == 1
            };
        }

        return null;
    }

    public async Task<AppUser?> GetUserById(string id)
    {
        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        await conn.OpenAsync();
        var cmd = conn.CreateCommand();
        cmd.CommandText = "SELECT Id, Name, Email, Password, IsAdmin FROM Users WHERE Id = $id";
        cmd.Parameters.AddWithValue("$id", id);
        using var reader = await cmd.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return new AppUser
            {
                Id = reader.GetString(0),
                Name = reader.GetString(1),
                Email = reader.GetString(2),
                Password = reader.GetString(3),
                IsAdmin = reader.GetInt32(4) == 1
            };
        }

        return null;
    }

    public async Task<AppUser> RegisterUser(RegisterRequest req)
    {
        var existing = await GetUserByEmail(req.Email);
        if (existing != null)
            throw new InvalidOperationException("User already exists");

        var user = new AppUser
        {
            Id = Guid.NewGuid().ToString(),
            Name = req.Name,
            Email = req.Email,
            Password = req.Password,
            IsAdmin = false
        };

        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        await conn.OpenAsync();
        var cmd = conn.CreateCommand();
        cmd.CommandText = @"INSERT INTO Users(Id, Name, Email, Password, IsAdmin) VALUES($id, $name, $email, $password, $isAdmin)";
        cmd.Parameters.AddWithValue("$id", user.Id);
        cmd.Parameters.AddWithValue("$name", user.Name);
        cmd.Parameters.AddWithValue("$email", user.Email);
        cmd.Parameters.AddWithValue("$password", user.Password);
        cmd.Parameters.AddWithValue("$isAdmin", user.IsAdmin ? 1 : 0);
        await cmd.ExecuteNonQueryAsync();

        return user;
    }

    public async Task<List<AccessLog>> GetLogs()
    {
        var result = new List<AccessLog>();
        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        await conn.OpenAsync();
        var cmd = conn.CreateCommand();
        cmd.CommandText = "SELECT Uid, UserId, Name, Direction, Timestamp, CardId FROM Logs ORDER BY Timestamp DESC";
        using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var ts = reader.IsDBNull(4) ? DateTime.UtcNow : DateTime.Parse(reader.GetString(4));
            result.Add(new AccessLog
            {
                Uid = reader.GetString(0),
                UserId = reader.IsDBNull(1) ? "" : reader.GetString(1),
                Name = reader.IsDBNull(2) ? "" : reader.GetString(2),
                Direction = reader.IsDBNull(3) ? "In" : reader.GetString(3),
                Timestamp = ts,
                CardId = reader.IsDBNull(5) ? "" : reader.GetString(5)
            });
        }

        return result;
    }

    public async Task AddLog(AccessLog log)
    {
        log.CardId = NormalizeCardId(log.CardId);
        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        await conn.OpenAsync();
        var cmd = conn.CreateCommand();
        cmd.CommandText = @"INSERT OR REPLACE INTO Logs(Uid, UserId, Name, Direction, Timestamp, CardId) VALUES($uid, $userId, $name, $direction, $timestamp, $cardId)";
        cmd.Parameters.AddWithValue("$uid", log.Uid);
        cmd.Parameters.AddWithValue("$userId", log.UserId ?? string.Empty);
        cmd.Parameters.AddWithValue("$name", log.Name ?? string.Empty);
        cmd.Parameters.AddWithValue("$direction", log.Direction ?? "In");
        cmd.Parameters.AddWithValue("$timestamp", log.Timestamp.ToString("o"));
        cmd.Parameters.AddWithValue("$cardId", log.CardId ?? string.Empty);
        await cmd.ExecuteNonQueryAsync();
    }

    public async Task MakeUserAdmin(string userId, string adminRequesterId)
    {
        var admin = await GetUserById(adminRequesterId);
        if (admin == null || !admin.IsAdmin)
            throw new InvalidOperationException("Only admins can promote users");

        var user = await GetUserById(userId);
        if (user == null)
            throw new InvalidOperationException("User not found");

        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        await conn.OpenAsync();
        var cmd = conn.CreateCommand();
        cmd.CommandText = "UPDATE Users SET IsAdmin = 1 WHERE Id = $id";
        cmd.Parameters.AddWithValue("$id", userId);
        await cmd.ExecuteNonQueryAsync();
    }

    public async Task<List<RfidCardEntry>> GetRegisteredCards()
    {
        var result = new List<RfidCardEntry>();
        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        await conn.OpenAsync();
        var cmd = conn.CreateCommand();
        cmd.CommandText = @"
            SELECT r.CardId, r.UserId, u.Name, u.IsAdmin
            FROM RfidCards r
            JOIN Users u ON r.UserId = u.Id
        ";
        using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            result.Add(new RfidCardEntry
            {
                uid = NormalizeCardId(reader.GetString(0)),
                userId = reader.GetString(1),
                person = reader.GetString(2),
                isAdmin = reader.GetInt32(3) == 1
            });
        }

        return result;
    }

    public async Task RegisterCard(string cardId, string userId)
    {
        cardId = NormalizeCardId(cardId);
        using var conn = new SqliteConnection($"Data Source={_dbPath}");
        await conn.OpenAsync();
        var cmd = conn.CreateCommand();
        cmd.CommandText = "INSERT OR REPLACE INTO RfidCards(CardId, UserId) VALUES($cardId, $userId)";
        cmd.Parameters.AddWithValue("$cardId", cardId);
        cmd.Parameters.AddWithValue("$userId", userId);
        await cmd.ExecuteNonQueryAsync();
    }
}
