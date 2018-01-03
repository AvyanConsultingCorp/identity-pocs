using System.Web.Mvc;

namespace IdentityScenarioOne.Controllers
{
    public class ErrorController : Controller
    {
        public ActionResult Index(string message)
        {
            ViewBag.Message = message;
            return View("Error");
        }
    }
}