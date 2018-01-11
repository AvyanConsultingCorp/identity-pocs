using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using System.Configuration;

namespace ScenarioOne.Webapp.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            if (!Request.IsAuthenticated)
            {
                return View();
            }
            else
            {
                
                var userClaims = User.Identity as System.Security.Claims.ClaimsIdentity;
                ViewBag.Name = userClaims?.FindFirst("name")?.Value;
                ViewBag.IpAdress = userClaims?.FindFirst("ipaddr")?.Value;
                ViewBag.Email = userClaims?.FindFirst(System.IdentityModel.Claims.ClaimTypes.Email)?.Value;
                ViewBag.Username = userClaims?.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value;
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
    }
}