﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using rhoruntime;

namespace RhoRuntimeInvoker
{
    [Windows.Foundation.Metadata.AllowForWeb]
    public sealed class RuntimeInvoker
    {
        public String invoke(String cmd)
        {
            return CRhoRuntime.getInstance().onJSInvoke(cmd);
        }
    }    

}