using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Collections.Concurrent;
using MQTTnet;
using MQTTnet.Client;
using NulpAccessApi.Models;
using NulpAccessApi.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddSingleton<IDataService, DataService>();
builder.Services.AddHostedService<MqttUserLookupResponder>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        policy => policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

var app = builder.Build();

app.UseCors("AllowAll");
app.UseWebSockets();

var jwtService = app.Services.GetRequiredService<IJwtService>();
var dataService = app.Services.GetRequiredService<IDataService>();

var connectedSockets = new ConcurrentDictionary<string, WebSocket>();

async Task StartMqttBridgeAsync()
{
    try
    {
        var factory = new MqttFactory();
        var mqttClient = factory.CreateMqttClient();
        var options = new MqttClientOptionsBuilder()
            .WithTcpServer("broker.hivemq.com", 1883)
            .WithClientId($"nulp_backend_bridge_{Guid.NewGuid()}")
            .Build();

        var cardPublishTimer = new Timer(async _ =>
        {
            if (mqttClient.IsConnected)
            {
                try
                {
                    var cards = await dataService.GetRegisteredCards();
                    var json = JsonSerializer.Serialize(cards, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
                    var applicationMessage = new MqttApplicationMessageBuilder()
                        .WithTopic("nulp/cards/sync")
                        .WithPayload(json)
                        .WithQualityOfServiceLevel(MQTTnet.Protocol.MqttQualityOfServiceLevel.AtLeastOnce)
                        .WithRetainFlag(true)
                        .Build();

                    await mqttClient.PublishAsync(applicationMessage);
                    Console.WriteLine($"[MQTT] Published {cards.Count} cards to nulp/cards/sync");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[MQTT] Error publishing cards: {ex.Message}");
                }
            }
        }, null, TimeSpan.FromSeconds(5), TimeSpan.FromSeconds(60));

        mqttClient.ConnectedAsync += async e =>
        {
            Console.WriteLine("[MQTT] Connected to broker");
            await mqttClient.SubscribeAsync(new MqttTopicFilterBuilder()
                .WithTopic("nulp/access/events")
                .Build());
            Console.WriteLine("[MQTT] Subscribed to nulp/access/events");

            await mqttClient.SubscribeAsync(new MqttTopicFilterBuilder()
                .WithTopic("nulp/cards/request")
                .Build());
            Console.WriteLine("[MQTT] Subscribed to nulp/cards/request");
        };

        mqttClient.DisconnectedAsync += async e =>
        {
            Console.WriteLine("[MQTT] Bridge disconnected, retrying in 5s...");
            await Task.Delay(TimeSpan.FromSeconds(5));
            try { await mqttClient.ConnectAsync(options, CancellationToken.None); }
            catch (Exception ex) { Console.WriteLine($"[MQTT] Reconnect failed: {ex.Message}"); }
        };

        mqttClient.ApplicationMessageReceivedAsync += async e =>
        {
            var payload = Encoding.UTF8.GetString(e.ApplicationMessage.Payload ?? Array.Empty<byte>());
            Console.WriteLine($"[MQTT] Message received: {payload}");
            try
            {
                var mqttPayload = JsonSerializer.Deserialize<MqttAccessLogPayload>(payload);
                var log = mqttPayload?.ToAccessLog();
                if (log != null)
                {
                    if (string.IsNullOrEmpty(log.UserId) && !string.IsNullOrEmpty(log.CardId))
                    {
                        var cards = await dataService.GetRegisteredCards();
                        var match = cards.FirstOrDefault(c => c.uid == log.CardId);
                        if (match != null)
                        {
                            log.UserId = match.userId;
                            if (string.IsNullOrEmpty(log.Name) || log.Name.Equals("UNKNOWN", StringComparison.OrdinalIgnoreCase))
                                log.Name = match.person;
                        }
                    }
                    await dataService.AddLog(log);
                    Console.WriteLine($"[DB] Log saved: {log.Uid} - {log.Name}");

                    var json = JsonSerializer.Serialize(new { type = "new", log }, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
                    var bytes = Encoding.UTF8.GetBytes(json);

                    Console.WriteLine($"[WS] Broadcasting to {connectedSockets.Count} clients");
                    foreach (var kv in connectedSockets)
                    {
                        var ws = kv.Value;
                        if (ws.State == WebSocketState.Open)
                        {
                            try
                            {
                                await ws.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
                                Console.WriteLine($"[WS] Sent to client {kv.Key}");
                            }
                            catch (Exception ex)
                            {
                                Console.WriteLine($"[WS] Error sending to {kv.Key}: {ex.Message}");
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[MQTT] Error parsing message: {ex.Message}");
            }
        };

        await mqttClient.ConnectAsync(options, CancellationToken.None);
        Console.WriteLine("[MQTT] Bridge started");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[MQTT] Bridge failed: {ex.Message}");
    }
}

_ = StartMqttBridgeAsync();

app.MapPost("/api/auth/register", async (RegisterRequest req, IDataService data, IJwtService jwt) =>
{
    try
    {
        var user = await data.RegisterUser(req);
        var token = jwt.GenerateToken(user);
        return Results.Ok(new AuthResponse { Token = token, User = user });
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

app.MapPost("/api/auth/login", async (LoginRequest req, IDataService data, IJwtService jwt) =>
{
    var user = await data.GetUserByEmail(req.Email);
    if (user == null || user.Password != req.Password)
        return Results.Unauthorized();

    var token = jwt.GenerateToken(user);
    return Results.Ok(new AuthResponse { Token = token, User = user });
});

app.MapGet("/api/user/me", async (HttpContext context, IDataService data, IJwtService jwt) =>
{
    var token = context.Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
    var userId = jwt.ValidateToken(token);
    if (userId == null)
        return Results.Unauthorized();

    var user = await data.GetUserById(userId);
    return Results.Ok(user);
});

app.MapPost("/api/user/register-card", async (HttpContext context, IDataService data, IJwtService jwt, string cardId) =>
{
    var token = context.Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
    var userId = jwt.ValidateToken(token);
    if (userId == null)
        return Results.Unauthorized();

    try
    {
        await data.RegisterCard(cardId, userId);
        return Results.Ok(new { message = "Card registered successfully", cardId });
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

app.MapGet("/api/logs", async (HttpContext context, IDataService data, IJwtService jwt) =>
{
    var token = context.Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
    var userId = jwt.ValidateToken(token);
    if (userId == null)
        return Results.Unauthorized();

    var user = await data.GetUserById(userId);
    var logs = await data.GetLogs();

    if (user?.IsAdmin == true)
        return Results.Ok(logs);
    else
        return Results.Ok(logs.Where(l => l.UserId == userId).ToList());
});

app.MapPost("/api/logs", async (AccessLog log, HttpContext context, IDataService data, IJwtService jwt) =>
{
    var token = context.Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
    var userId = jwt.ValidateToken(token);
    if (userId == null)
        return Results.Unauthorized();

    log.UserId = userId;
    log.Timestamp = DateTime.UtcNow;
    await data.AddLog(log);
    return Results.Ok(log);
});

app.MapGet("/api/cards", async (IDataService data) =>
{
    var cards = await data.GetRegisteredCards();
    return Results.Ok(cards);
});

app.Map("/ws/logs", async (HttpContext context) =>
{
    if (!context.WebSockets.IsWebSocketRequest)
    {
        context.Response.StatusCode = 400;
        return;
    }

    var webSocket = await context.WebSockets.AcceptWebSocketAsync();
    var buffer = new byte[1024 * 4];
    var id = Guid.NewGuid().ToString();
    connectedSockets.TryAdd(id, webSocket);
    Console.WriteLine($"[WS] Client connected: {id}, total: {connectedSockets.Count}");

    try
    {
        var allLogs = await dataService.GetLogs();
        var historyJson = JsonSerializer.Serialize(
            new { type = "history", logs = allLogs },
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }
        );
        var historyBytes = Encoding.UTF8.GetBytes(historyJson);
        await webSocket.SendAsync(new ArraySegment<byte>(historyBytes), WebSocketMessageType.Text, true, CancellationToken.None);
        Console.WriteLine($"[WS] Sent {allLogs.Count} historical logs to {id}");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[WS] Failed to send history to {id}: {ex.Message}");
    }

    try
    {
        while (webSocket.State == WebSocketState.Open)
        {
            WebSocketReceiveResult result;
            try
            {
                result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
            }
            catch (WebSocketException)
            {
                Console.WriteLine($"[WS] WebSocketException for {id}");
                break;
            }

            if (result.MessageType == WebSocketMessageType.Close)
            {
                if (webSocket.State == WebSocketState.Open ||
                    webSocket.State == WebSocketState.CloseReceived)
                {
                    await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", CancellationToken.None);
                }
            }
            else
            {
                var message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                try
                {
                    var log = JsonSerializer.Deserialize<AccessLog>(message);
                    if (log != null)
                    {
                        await dataService.AddLog(log);
                        var response = JsonSerializer.Serialize(log);
                        var responseBytes = Encoding.UTF8.GetBytes(response);
                        await webSocket.SendAsync(new ArraySegment<byte>(responseBytes), WebSocketMessageType.Text, true, CancellationToken.None);
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[WS] Error parsing message: {ex.Message}");
                }
            }
        }
    }
    finally
    {
        connectedSockets.TryRemove(id, out _);
        Console.WriteLine($"[WS] Client disconnected: {id}, remaining: {connectedSockets.Count}");
        try
        {
            webSocket.Dispose();
        }
        catch
        {
        }
    }
});

app.MapPost("/api/admin/make-admin", async (string userId, HttpContext context, IDataService data, IJwtService jwt) =>
{
    var token = context.Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
    var adminId = jwt.ValidateToken(token);
    if (adminId == null)
        return Results.Unauthorized();

    try
    {
        await data.MakeUserAdmin(userId, adminId);
        var user = await data.GetUserById(userId);
        return Results.Ok(new { message = "User promoted to admin", user });
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

app.Run("http://0.0.0.0:5000");
