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

namespace IdentityScenarioOne.Webapp.Controllers
{
    public class HomeController : Controller
    {
        static AuthenticationResult result;
        public async Task<ActionResult> Index()
        {
            if (!Request.IsAuthenticated)
            {
                return View();
            }
            else
            {
                
                var userClaims = User.Identity as System.Security.Claims.ClaimsIdentity;

                //You get the user’s first and last name below:
                ViewBag.Name = userClaims?.FindFirst("name")?.Value;
                ViewBag.IpAdress = userClaims?.FindFirst("ipaddr")?.Value;
                ViewBag.Email = userClaims?.FindFirst(System.IdentityModel.Claims.ClaimTypes.Email)?.Value;
                ViewBag.Username = userClaims?.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value;
                string adAppClientId = ConfigurationManager.AppSettings["adAppClientId"];
                string authority = ConfigurationManager.AppSettings["tenantDomain"];
                string adAppClientPassword = ConfigurationManager.AppSettings["adAppClientPassword"];
                var clientCredential = new ClientCredential(adAppClientId, adAppClientPassword);
                string targetURL = ConfigurationManager.AppSettings["targetURL"];
                var authContext = new Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(authority, false);
                result = await authContext.AcquireTokenAsync("https://graph.windows.net", clientCredential);
                ViewBag.AuthToken = result.AccessToken;
                string userObjectID = ClaimsPrincipal.Current.FindFirst("http://schemas.microsoft.com/identity/claims/objectidentifier").Value;
                string resourceId = ConfigurationManager.AppSettings["resourceId"];
                string userToken = null;
                Task.Run(
                async () => {
                    userToken = await Authentication.GetUserToken(adAppClientId, adAppClientPassword, authority, userObjectID, resourceId);
                }).Wait();

                string target = targetURL + "/User/Details/" + result.AccessToken;
                ViewBag.detailUrl = target;
                // TenantId is the unique Tenant Id - which represents an organization in Azure AD
                //ViewBag.TenantId = userClaims?.FindFirst("http://schemas.microsoft.com/identity/claims/tenantid")?.Value;
                return View();
            }
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