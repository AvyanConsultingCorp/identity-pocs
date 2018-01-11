﻿using System;
using System.Configuration;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Scenario2.TargetWebApp.Controllers
{
    using Models;
    using Common;

    public class UserController : Controller
    {
        const string authIssuer = "https://demo-client-webapp.azurewebsites.net"; // Client Domain

        private string authAudience = ConfigurationManager.AppSettings["ClientId"]; // Target Domain

        // GET: User
        public ActionResult Index()
        {
            return View();
        }

        [Route("{authToken}")]
        [HttpGet]
        public ActionResult Details(string authToken)
        {
            TokenData tokenData = new TokenData();
            if (JwtTokenValidator.Validate(authIssuer, authAudience, authToken,ref tokenData))
            {
                return View(tokenData);
            }
            else
            {
                return View("Error");
            }
        }
    }
}