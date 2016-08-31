using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace o365SmartLink
{
    public class Startup
    {
        // This method gets called by the runtime. Use this method to add services to the container.
        // For more information on how to configure your application, visit http://go.microsoft.com/fwlink/?LinkID=398940
        public void ConfigureServices(IServiceCollection services)
        {
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env, ILoggerFactory loggerFactory)
        {
            loggerFactory.AddConsole();

            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            string redirectUrl = "https://idp.feide.no/simplesaml/module.php/feide/preselectOrg.php?HomeOrg=uninett.no&ReturnTo=https%3A//login.microsoftonline.com/%3Fwhr%3Duninett.no";

            app.Run(async (context) =>
            {
                await Task.Run(() => context.Response.Redirect(redirectUrl));
            });
        }
    }
}
