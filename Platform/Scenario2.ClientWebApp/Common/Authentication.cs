using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Scenario2.TargetWebApp.Common
{
    public static class Authentication
    {
        public static async Task<string> GetS2SToken(string clientId, string password,string authority,string resourceId)
        {
            var clientCredential = new ClientCredential(clientId, password);

            var authContext = new AuthenticationContext(authority, false);
            var result = await authContext.AcquireTokenAsync(resourceId, clientCredential);

            if (result == null)
            {
                throw new Exception("Failed to obtain S2S token");
            }

            return result.AccessToken;
        }

        public static async Task<string> GetUserToken(string clientId,string password,string authority,string userId,string resourceId)
        {
            AuthenticationContext authContext = new AuthenticationContext(authority, false);
            ClientCredential credential = new ClientCredential(clientId, password);
            var result = await authContext.AcquireTokenAsync(resourceId, credential);


            if (result == null)
            {
                throw new Exception("Failed to obtain User token");
            }

            return result.AccessToken;
        }
    }
}