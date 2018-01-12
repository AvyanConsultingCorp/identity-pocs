
namespace Scenario2.TargetWebApp.Filters
{
    using System.Configuration;
    using System.Web.Mvc;
    using Common;
    using Scenario2.TargetWebApp.Models;

    public class AccessTokenFilter : IActionFilter
    {
        public void OnActionExecuted(ActionExecutedContext filterContext)
        {
            
        }

        public void OnActionExecuting(ActionExecutingContext filterContext)
        {
            var token = filterContext.RequestContext.HttpContext.Request.QueryString.Get("authToken");
            var tokenData = new TokenData();
            if (!JwtTokenValidator.Validate(ConfigurationManager.AppSettings["ADAppClientId"], token, ref tokenData))
            {
                filterContext.Result = new ViewResult
                {
                    ViewName = "401"
                };
            }
           
        }
    }
}