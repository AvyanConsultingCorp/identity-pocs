
namespace Scenario2.TargetWebApp.Filters
{
    using System.Configuration;
    using System.Web.Mvc;
    using Common;

    public class AccessTokenFilter : IActionFilter
    {
        public void OnActionExecuted(ActionExecutedContext filterContext)
        {
            throw new System.NotImplementedException();
        }

        public void OnActionExecuting(ActionExecutingContext filterContext)
        {
           
            filterContext.Result = new ViewResult
            {
                ViewName = "Error"
            };
        }
    }
}