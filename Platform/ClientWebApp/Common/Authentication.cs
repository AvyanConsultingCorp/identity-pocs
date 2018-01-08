using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ClientWebApp.Common
{
    public static class Authentication
    {
        public static string GetS2SToken()
        {
            var clientCredential = new ClientCredential(adAppClientId, adAppClientPassword);

            var authContext = new Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(authority, false);
            result = await authContext.AcquireTokenAsync("https://graph.windows.net", clientCredential);
            ViewBag.AuthToken = result.AccessToken;
        }

        public static string GetUserToken(string clientId,string password)
        {

        }
    }
}