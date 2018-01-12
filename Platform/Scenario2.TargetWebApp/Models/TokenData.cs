using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Scenario2.TargetWebApp.Models
{
    public class TokenData
    {
        public string ApplicationId { get; set; }

        public string AuthenticationType { get; set; }

        public string Issuer { get; set; }

        public DateTime ValidFrom { get; set; }

        public DateTime ValidTo { get; set; }

        public DateTime ExpiryDate { get; set; }
    }
}