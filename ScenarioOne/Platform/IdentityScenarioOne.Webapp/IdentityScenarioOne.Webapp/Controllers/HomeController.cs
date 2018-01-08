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

                var authContext = new Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(authority, false);
                result = await authContext.AcquireTokenAsync("https://graph.windows.net", clientCredential);
                ViewBag.AuthToken = result.AccessToken;

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
            string tenantId = ConfigurationManager.AppSettings["tenantId"];
            string redirectURI = "https://login.microsoftonline.com/"+ tenantId + "/oauth2/logout?post_logout_redirect_uri=" + webAppURL;
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