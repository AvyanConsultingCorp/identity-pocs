﻿using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using System.Threading;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System;
using Scenario2.TargetWebApp.Models;
using System.Collections.Generic;

namespace Scenario2.TargetWebApp.Common
{
    public static class JwtTokenValidator
    {

        
        public static bool Validate(string authAudience, string token,ref TokenData tokenData)
        {
            string stsDiscoveryEndpoint = "https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration";


            ConfigurationManager<OpenIdConnectConfiguration> configManager
                = new ConfigurationManager<OpenIdConnectConfiguration>(stsDiscoveryEndpoint, 
                new OpenIdConnectConfigurationRetriever());
            OpenIdConnectConfiguration config = configManager.GetConfigurationAsync().Result;
            TokenValidationParameters validationParameters = new TokenValidationParameters
            {
                ValidateAudience = true,
                ValidateIssuer = false,
                ValidateLifetime = false,
                ValidAudience = authAudience,
                IssuerSigningKeys = config.SigningKeys
            };

            JwtSecurityTokenHandler tokendHandler = new JwtSecurityTokenHandler();
            SecurityToken jwt;

            try
            {
                var result = tokendHandler.ValidateToken(token, validationParameters, out jwt);

                var data = new Dictionary<string, string>();

                foreach(var claim in result.Claims)
                {
                    data.Add(claim.Type, claim.Value);
                }

                tokenData.AuthenticationType = result.Identity.AuthenticationType;
                tokenData.ApplicationId = data["appid"];
                tokenData.Issuer = jwt.Issuer;
                tokenData.ValidFrom = jwt.ValidFrom;
                tokenData.ValidTo = jwt.ValidTo;
                tokenData.ExpiryDate = new DateTime(Convert.ToInt64(data["exp"]));
                return true;
            }
            catch(Exception ex)
            {
                return false;
            }

           
        }
    }
}
