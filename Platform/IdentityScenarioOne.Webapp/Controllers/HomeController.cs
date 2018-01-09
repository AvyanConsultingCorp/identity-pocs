using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using System.Configuration;
using IdentityScenarioOne.Webapp.Common;
using System.Security.Claims;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights;

namespace IdentityScenarioOne.Webapp.Controllers
{
    public class HomeController : Controller
    {
        private static RequestTelemetry telemetryRequest = new RequestTelemetry();
        private static TelemetryClient telemetryClient = new TelemetryClient()
        {
            InstrumentationKey = ConfigurationManager.AppSettings["APPINSIGHTS_INSTRUMENTATIONKEY"]
        };
        static AuthenticationResult result;

        string adAppClientId = ConfigurationManager.AppSettings["ClientId"];
        string tenant = $"{ConfigurationManager.AppSettings["TenantDomain"]}";
        string adAppClientPassword = ConfigurationManager.AppSettings["ClientSecret"];
        string targetURL = ConfigurationManager.AppSettings["TargetEndpoint"];
        string targetAppId = ConfigurationManager.AppSettings["TenantAppId"];
        public HomeController()
        {
            CreateTelemetryClient();
        }

        private static void CreateTelemetryClient()
        {
            telemetryRequest.GenerateOperationId();
            telemetryClient.Context.Operation.Id = telemetryRequest.Id;
            telemetryRequest.Context.Operation.Name = "Application auth";
        }

        public async Task<ActionResult> Index()
        {
            string userToken = string.Empty;
            try
            {
                if (!Request.IsAuthenticated)
                {
                    return View();
                }
                else
                {
                    Task.Run(
                   async () =>
                   {
                       var userClaims = User.Identity as System.Security.Claims.ClaimsIdentity;

                       //You get the user’s first and last name below:
                       ViewBag.Name = userClaims?.FindFirst("name")?.Value;
                       ViewBag.IpAdress = userClaims?.FindFirst("ipaddr")?.Value;
                       ViewBag.Email = userClaims?.FindFirst(System.IdentityModel.Claims.ClaimTypes.Email)?.Value;
                       ViewBag.Username = userClaims?.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value;

                       var clientCredential = new ClientCredential(adAppClientId, adAppClientPassword);

                       //var authContext = new Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(authority, false);
                       //result = await authContext.AcquireTokenAsync("https://graph.windows.net", clientCredential);
                       //ViewBag.AuthToken = result.AccessToken;
                       string userObjectID = ClaimsPrincipal.Current.FindFirst("http://schemas.microsoft.com/identity/claims/objectidentifier").Value;
                       //string resourceId = ConfigurationManager.AppSettings["resourceId"];

                       var authority = $"https://login.microsoftonline.com/{tenant}";
                       userToken = await Authentication.GetUserToken(adAppClientId, adAppClientPassword, authority, userObjectID, targetAppId);
                   }).Wait();

                    string target = targetURL + "/User/Details?authToken=" + userToken;
                    ViewBag.detailUrl = target;
                    ViewBag.AuthToken = userToken;
                    // TenantId is the unique Tenant Id - which represents an organization in Azure AD
                    //ViewBag.TenantId = userClaims?.FindFirst("http://schemas.microsoft.com/identity/claims/tenantid")?.Value;
                }
            }
            catch (Exception ex)
            {
                telemetryClient.TrackException(ex);
            }
            return View();
        }

        public ActionResult signout()
        {
            string[] myCookies = Request.Cookies.AllKeys;
            foreach (string cookie in myCookies)
            {
                Response.Cookies[cookie].Expires = DateTime.Now.AddDays(-1);
            }
            string webAppURL = ConfigurationManager.AppSettings["webAppURL"];
            string redirectURI = "https://login.microsoftonline.com/46d804b6-210b-4a4a-9304-83b93e71784d/oauth2/logout?post_logout_redirect_uri=" + webAppURL;
            return Redirect(redirectURI);
        }

        public ActionResult About()
        {
            ViewBag.Message = "Your application description page.";

            return View();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }
    }
}