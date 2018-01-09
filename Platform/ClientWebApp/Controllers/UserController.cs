using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace ClientWebApp.Controllers
{
    using Models;
    using Common;

    public class UserController : Controller
    {
        const string authIssuer = "https://um-auth-client.azurewebsites.net"; // Client Domain

        const string authAudience = "5e821316-b61b-4f0a-bbcd-0cdf1932be3f"; // Target Domain

        // GET: User
        public ActionResult Index()
        {
            return View();
        }

        [Route("{authToken}")]
        [HttpGet]
        public ActionResult Details(string authToken)
        {
            JwtTokenValidator.Validate(authIssuer, authAudience, authToken);
            return View(user);
        }
    }
}