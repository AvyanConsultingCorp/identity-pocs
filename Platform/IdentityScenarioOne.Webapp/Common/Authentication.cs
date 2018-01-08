using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace IdentityScenarioOne.Webapp.Common
{
    public static class Authentication
    {
        public static async Task<string> GetS2SToken(string clientId, string password,string authority)
        {
            var clientCredential = new ClientCredential(clientId, password);

            var authContext = new AuthenticationContext(authority, false);
            var result = await authContext.AcquireTokenAsync("https://graph.windows.net", clientCredential);

            if (result == null)
            {
                throw new Exception("Failed to obtain S2S token");
            }

            return result.AccessToken;
        }

        public static async Task<string> GetUserToken(string clientId,string password,string authority,string userId,string resourceId)
        {
            //string userObjectID = ClaimsPrincipal.Current.FindFirst("http://schemas.microsoft.com/identity/claims/objectidentifier").Value;
            AuthenticationContext authContext = new AuthenticationContext(authority, new NaiveSessionCache(userId));
            ClientCredential credential = new ClientCredential(clientId, password);
            var result = await authContext.AcquireTokenSilentAsync(resourceId, credential, new UserIdentifier(userId, UserIdentifierType.UniqueId));

            if (result == null)
            {
                throw new Exception("Failed to obtain User token");
            }

            return result.AccessToken;
        }
    }
}