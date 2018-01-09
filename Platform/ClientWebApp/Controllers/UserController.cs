using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace ClientWebApp.Controllers
{
    using Models;

    public class UserController : Controller
    {
        // GET: User
        public ActionResult Index()
        {
            return View();
        }

        [Route("{authToken}")]
        [HttpGet]
        public ActionResult Details(string authToken)
        {
            var user = new NBMEUser { AuthToken = authToken };
            return View(user);
        }
    }
}