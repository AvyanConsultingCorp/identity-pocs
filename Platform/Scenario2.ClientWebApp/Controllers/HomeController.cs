﻿using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using System.Configuration;
using Scenario2.TargetWebApp.Common;
using System.Security.Claims;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights;

namespace Scenario2.TargetWebApp.Controllers
{
    public class HomeController : Controller
    {
        string adAppClientId = ConfigurationManager.AppSettings["ClientId"];
        string tenant = ConfigurationManager.AppSettings["TenantDomain"];
        string adAppClientPassword = ConfigurationManager.AppSettings["ClientSecret"];
        string targetURL = ConfigurationManager.AppSettings["TargetEndpoint"];
        string targetAppId = ConfigurationManager.AppSettings["TargetAppId"];

        public HomeController()
        {
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
                       var authority = $"https://login.microsoftonline.com/{tenant}";
                       userToken = await Authentication.GetUserToken(adAppClientId, adAppClientPassword, authority, targetAppId);
                   }).Wait();

                    string target = targetURL + "/User/Details?authToken=" + userToken;
                    ViewBag.detailUrl = target;
                    ViewBag.appUrl = targetURL+ "/User/Details";
                    ViewBag.AuthToken = userToken;
                }
            }
            catch (Exception ex)
            {
                
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