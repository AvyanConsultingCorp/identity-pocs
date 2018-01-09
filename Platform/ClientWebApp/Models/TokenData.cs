using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Scenario2.TargetWebApp.Models
{
    public class TokenData
    {
        public string Issuer { get; set; }

        public DateTime ValidFrom { get; set; }

        public DateTime ValidTo { get; set; }
    }
}