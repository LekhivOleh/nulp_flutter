using System.Text;
using System.Text.Json;
using MQTTnet;
using MQTTnet.Client;

namespace NulpAccessApi.Services;

public class MqttUserLookupResponder(
    IDataService dataService,
    ILogger<MqttUserLookupResponder> logger
) : BackgroundService
{
    private const string QueryTopic = "nulp/users/query";
    private const string BrokerHost  = "broker.hivemq.com";
    private const int    BrokerPort  = 1883;

    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            try   { await RunAsync(ct); }
            catch (Exception ex) when (!ct.IsCancellationRequested)
            {
                logger.LogWarning(ex, "MQTT lookup responder disconnected, retrying in 5s");
                await Task.Delay(TimeSpan.FromSeconds(5), ct);
            }
        }
    }

    private async Task RunAsync(CancellationToken ct)
    {
        var factory = new MqttFactory();
        using var client = factory.CreateMqttClient();

        var options = new MqttClientOptionsBuilder()
            .WithTcpServer(BrokerHost, BrokerPort)
            .WithClientId($"dotnet_lookup_responder_{Guid.NewGuid():N}")
            .WithCleanSession()
            .Build();

        client.ApplicationMessageReceivedAsync += msg => HandleQueryAsync(client, msg, ct);

        await client.ConnectAsync(options, ct);
        await client.SubscribeAsync(QueryTopic, cancellationToken: ct);

        logger.LogInformation("MQTT user lookup responder connected, listening on {Topic}", QueryTopic);

        await Task.Delay(Timeout.Infinite, ct);
    }

    private async Task HandleQueryAsync(IMqttClient client, MqttApplicationMessageReceivedEventArgs e, CancellationToken ct)
    {
        QueryPayload? query;
        try
        {
            var payload = e.ApplicationMessage.Payload ?? Array.Empty<byte>();
            var json = Encoding.UTF8.GetString(payload);
            query = JsonSerializer.Deserialize<QueryPayload>(json, JsonOptions);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to parse MQTT user query payload");
            return;
        }

        if (query is null || string.IsNullOrEmpty(query.CardId) ||
            string.IsNullOrEmpty(query.RequestId) || string.IsNullOrEmpty(query.ReplyTo))
            return;

        string userId = "", name = "Unknown";
        try
        {
            var normalizedCardId = NormalizeCardId(query.CardId);
            var cards = await dataService.GetRegisteredCards();
            var match = cards.FirstOrDefault(card => NormalizeCardId(card.uid) == normalizedCardId);

            if (match is not null)
            {
                userId = match.userId;
                name = match.person;
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "DB lookup failed for cardId {CardId}", query.CardId);
        }

        var response = JsonSerializer.Serialize(new
        {
            requestId = query.RequestId,
            userId,
            name,
        }, JsonOptions);

        var message = new MqttApplicationMessageBuilder()
            .WithTopic(query.ReplyTo)
            .WithPayload(response)
            .WithQualityOfServiceLevel(MQTTnet.Protocol.MqttQualityOfServiceLevel.AtLeastOnce)
            .Build();

        await client.PublishAsync(message, ct);
    }

    private static string NormalizeCardId(string cardId) =>
        cardId.Replace(":", string.Empty).ToUpperInvariant();

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
    };

    private sealed class QueryPayload
    {
        public string CardId { get; set; } = "";
        public string RequestId { get; set; } = "";
        public string ReplyTo { get; set; } = "";
    }
}
