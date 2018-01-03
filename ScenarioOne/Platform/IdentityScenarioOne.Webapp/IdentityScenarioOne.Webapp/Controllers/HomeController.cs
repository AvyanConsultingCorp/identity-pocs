using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;

namespace IdentityScenarioOne.Controllers
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

                //You get the user’s first and last name below:
                ViewBag.Name = userClaims?.FindFirst("name")?.Value;
                ViewBag.IpAdress = userClaims?.FindFirst("ipaddr")?.Value;
                ViewBag.Email = userClaims?.FindFirst(System.IdentityModel.Claims.ClaimTypes.Email)?.Value;
                ViewBag.Username = userClaims?.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value;

                // TenantId is the unique Tenant Id - which represents an organization in Azure AD
                //ViewBag.TenantId = userClaims?.FindFirst("http://schemas.microsoft.com/identity/claims/tenantid")?.Value;
                return View();
            }

        }

    }
}