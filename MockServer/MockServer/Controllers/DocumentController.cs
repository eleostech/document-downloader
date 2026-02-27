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
            // Hardcoding metadata to avoid file path issues in Docker/Linux
            var metadata = new Metadata
            {
                SentToEmail = "docs@example.com",
                DocumentIdentifier = 101298333,
                NumberOfPages = 2,
                CustomMetadata = new CustomMetadata { YourField = "example value" },
                ScannedByEmail = "jeff.tobin@example.com",
                DownloadUrl = new Uri("https://axle-staging.s3-external-1.amazonaws.com/packaged-tiffs/748f0170-14f5-0139-7600-4a842316cd76-789.zip?AWSAccessKeyId=AKIAYKFM34B2EPESFCOT&Signature=S7QrWtvXHX0bvW9s4hA0XY0r1kc%3D&Expires=1606777938&response-content-disposition=attachment%3B%20filename%3D%22_UNK__NA__2020-11-30T045019Z_57220.zip%22"),
                ScannedByUsername = "TOBJE9090",
                ScannedBy = "Jeff Tobb",
                UploadFinishedAt = DateTimeOffset.Parse("2019-08-11T20:15:22.2313+00:00"),
                BillOfLadingNumber = "9090192ABF",
                LoadNumber = "19289999-1",
                DocumentTypes = new string[] { "Bill of Lading" }
            };

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
