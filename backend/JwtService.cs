using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using NulpAccessApi.Models;

namespace NulpAccessApi.Services;

public interface IJwtService
{
    string GenerateToken(AppUser user);
    string? ValidateToken(string token);
}

public class JwtService : IJwtService
{
    private readonly string _secretKey = "BIBIKACHIPICHIKANIKGASMHIGGASHIKERSHPOCHOCKOMIBOMBOCLADAWBEBENINNICHOCKOPIENS";
    private readonly string _issuer = "NulpAccessApi";
    private readonly string _audience = "NulpAccessApp";

    public string GenerateToken(AppUser user)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.Name),
        };

        var token = new JwtSecurityToken(
            issuer: _issuer,
            audience: _audience,
            claims: claims,
            expires: DateTime.UtcNow.AddHours(24),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string? ValidateToken(string token)
    {
        try
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secretKey));
            var handler = new JwtSecurityTokenHandler();
            handler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = key,
                ValidateIssuer = true,
                ValidIssuer = _issuer,
                ValidateAudience = true,
                ValidAudience = _audience,
                ValidateLifetime = true,
            }, out SecurityToken validatedToken);

            var jwtToken = (JwtSecurityToken)validatedToken;
            return jwtToken.Claims.First(x => x.Type == ClaimTypes.NameIdentifier).Value;
        }
        catch
        {
            return null;
        }
    }
}
