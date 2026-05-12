namespace NulpAccessApi.Models;

public class AppUser
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
    public bool IsAdmin { get; set; }
}

public class AccessLog
{
    public string Uid { get; set; } = Guid.NewGuid().ToString();
    public string UserId { get; set; } = "";
    public string Name { get; set; } = "";
    public string Direction { get; set; } = "In";
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string CardId { get; set; } = "";
}

public class LoginRequest
{
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
}

public class RegisterRequest
{
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
}

public class AuthResponse
{
    public string Token { get; set; } = "";
    public AppUser User { get; set; } = new();
}

public class MqttAccessLogPayload
{
    public string device { get; set; } = "";
    public string uid { get; set; } = "";
    public string userId { get; set; } = "";
    public string name { get; set; } = "";
    public string direction { get; set; } = "IN";
    public string timestamp { get; set; } = DateTime.UtcNow.ToString("o");
    public string cardId { get; set; } = "";

    public AccessLog ToAccessLog()
    {
        return new AccessLog
        {
            Uid = Guid.NewGuid().ToString(),
            UserId = userId,
            Name = name,
            Direction = direction.ToUpperInvariant() switch
            {
                "OUT" => "Out",
                "DENIED" => "Denied",
                _ => "In"
            },
            Timestamp = DateTime.TryParse(timestamp, out var ts) ? ts : DateTime.UtcNow,
            CardId = string.IsNullOrEmpty(cardId) ? uid : cardId
        };
    }
}

public class RfidCardEntry
{
    public string uid { get; set; } = "";
    public string person { get; set; } = "";
    public string userId { get; set; } = "";
    public bool isAdmin { get; set; }
}
