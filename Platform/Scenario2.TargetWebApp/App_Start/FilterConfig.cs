using System.Web;
using System.Web.Mvc;

namespace Scenario2.TargetWebApp
{
    using Filters;

    public class FilterConfig
    {
        public static void RegisterGlobalFilters(GlobalFilterCollection filters)
        {
            filters.Add(new HandleErrorAttribute());
            filters.Add(new AccessTokenFilter());
        }
    }
}
