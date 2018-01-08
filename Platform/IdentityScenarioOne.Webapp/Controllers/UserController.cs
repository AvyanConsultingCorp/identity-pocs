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
    public class UserController : Controller
    {
        

        public ActionResult Details(string authToken)
        {
            return Redirect($"/details/{authToken}");
        }
    }
}