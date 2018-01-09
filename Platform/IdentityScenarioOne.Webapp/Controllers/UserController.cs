using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using System.Configuration;

namespace IdentityScenarioOne.Webapp.Controllers
{
    using Common;

    public class UserController : Controller
    {
        private readonly string ServiceEndpoint = ConfigurationManager.AppSettings["TargetEndpoint"];
        private readonly string clientId = ConfigurationManager.AppSettings["ClientId"];
        private readonly string password = ConfigurationManager.AppSettings["ClientSecret"];
        private readonly string tenantName = ConfigurationManager.AppSettings["TenantName"];

        public ActionResult Details(string authToken)
        {
            //var s2sToken = Authentication.GetS2SToken(clientId, password, $"https://login.microsoft.com/{tenantName}");
            //Request.Headers.Add("Authorization", $"Bearer {s2sToken}");
            return Redirect($"{ServiceEndpoint}/user/details?{authToken}");
        }
    }
}