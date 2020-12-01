using System;
using System.IO;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc;
using MockServer.Models;
using Newtonsoft.Json;


namespace MockServer.Controllers
{
    [ApiController]
    [Route("/api/v1/documents/queued/")]
    public class DocumentController : ControllerBase
    {
        [HttpDelete]
        [Route("/api/v1/documents/queued/1")]
        public Object Delete200()
        {
            Response.StatusCode = 200;
            Response.ContentType = "application/json";
            Dictionary<string, string> response = new Dictionary<string, string>();
            response.Add("message", "Document deleted successfully.");
            return response;
        }

        [Route("/api/v1/documents/queued/2")]
        public string Delete404()
        {
            Response.StatusCode = 404;
            Response.ContentType = "application/json";
            return "Error removing document.";
        }

        [Route("/api/v1/documents/queued/3")]
        public string Delete500()
        {
            Response.StatusCode = 500;
            Response.ContentType = "application/json";
            return "Internal server error";
        }

        [HttpGet]
        [Route("/api/v1/documents/queued/next")]
        public void FetchNextSuccess()
        {
            Response.StatusCode = 302;
            Response.Headers.Add("Location", "/api/v1/documents/queued/1");
        }

        [Route("/api/v1/documents/queued/next/empty")]
        public Object FetchNextEmpty()
        { 
            Response.StatusCode = 304;
            Response.ContentType = "application/json";
            return null;
        }

        [Route("/api/v1/documents/queued/next/fail")]
        public void FetchNextFail()
        {
            Response.StatusCode = 404;
        }

        [Route("/api/v1/documents/queued/next/badserver")]
        public void FetchNextBadServer()
        {
            Response.StatusCode = 500;
        }

        [HttpGet]
        [Route("/api/v1/documents/queued/1")]
        public Metadata DownloadDoc()
        {
            var directory = Environment.CurrentDirectory;
            StreamReader r = new StreamReader(directory + @"\Payloads\payload.json");
            string json = r.ReadToEnd();
            var metadata = JsonConvert.DeserializeObject<Metadata>(json);
            Response.ContentType = "application/json";
            Response.StatusCode = 200;
            return metadata;
        }

        [HttpGet]
        [Route("/api/v1/documents/queued/2")]
        public void DocNotFound()
        { 
            Response.ContentType = "application/json";
            Response.StatusCode = 404;
        }

        [HttpGet]
        [Route("/api/v1/documents/queued/3")]
        public void BadServer()
        {
            Response.ContentType = "application/json";
            Response.StatusCode = 500;
        }

        [HttpGet]
        [Route("/api/download/mock_server_file.png")]
        public void HeaderResponse()
        {
            var headers = Response.Headers;
        }

        [HttpGet]
        [Route("/api/download/validHeader")]
         public void ValidHeader()
        {
            var contentDisposition = "form-data; name=\"filename = \"; filename=\"filename.jpg\"";
            Response.Headers.Add("Content-Disposition", contentDisposition);
        }

        [HttpGet]
        [Route("/api/download/multipledelimeter")]
        public void MultipleDelimeter()
        {
            var contentDisposition = "form-data; name=\"filename = \"; filename=\"_NA__NA__; 2020-09.zip\"";
            Response.Headers.Add("Content-Disposition", contentDisposition);
        }

        [HttpGet]
        [Route("/api/content-disp/somefile.tif")]

        public void ContentDispositon()
        {
            var filename = @"""file.tif""";
            var contentDisp = "aaaaaaaaaaaa filename=" + filename;
            Response.Headers.Add("Content-Disposition", contentDisp);
        }

        [HttpGet]
        [Route("/api/badheader")]
        public void BadHeader()
        {

        }
    }
}