using System;
using System.IO;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc;
using MockServer.Models;
using Newtonsoft.Json;
using System.Linq;

namespace MockServer.Controllers
{
    [ApiController]
    [Route("/api/v1/documents/queued")]
    public class DocumentController : ControllerBase
    {
        private bool ValidateAuth()
        {
            if (!Request.Headers.TryGetValue("Authorization", out var authHeader))
            {
                return false;
            }

            var auth = authHeader.FirstOrDefault();
            if (string.IsNullOrEmpty(auth))
            {
                return false;
            }

            return auth.StartsWith("Key key=") || auth.StartsWith("DriveAxleKey key=");
        }

        [HttpGet("/health")]
        public IActionResult Health()
        {
            return Ok("Ready");
        }

        [HttpGet("next")]
        public IActionResult FetchNext()
        {
            if (!ValidateAuth()) return Unauthorized();

            // Support a special header or query to simulate empty queue
            if (Request.Headers.ContainsKey("X-Simulate-Empty"))
            {
                return StatusCode(304);
            }

            Response.Headers.Add("Location", "/api/v1/documents/queued/1");
            return StatusCode(302);
        }

        [HttpGet("next/empty")]
        public IActionResult FetchNextEmpty()
        {
            if (!ValidateAuth()) return Unauthorized();
            return StatusCode(304);
        }

        [HttpGet("{id}")]
        public IActionResult GetDocument(string id)
        {
            if (!ValidateAuth()) return Unauthorized();

            if (id == "2") return NotFound();

            var directory = AppContext.BaseDirectory;
            var filePath = Path.Combine(directory, "Payloads", "payload.json");
            
            if (!System.IO.File.Exists(filePath))
            {
                return StatusCode(500, "Payload file not found.");
            }

            using (StreamReader r = new StreamReader(filePath))
            {
                string json = r.ReadToEnd();
                var metadata = JsonConvert.DeserializeObject<Metadata>(json);
                return Ok(metadata);
            }
        }

        [HttpDelete("{id}")]
        public IActionResult DeleteDocument(string id)
        {
            if (!ValidateAuth()) return Unauthorized();

            if (id == "2") return NotFound();

            return Ok(new { message = "Document deleted successfully." });
        }

        // Additional endpoints for filename extraction tests
        [HttpGet("/api/download/validHeader")]
        public IActionResult ValidHeader()
        {
            var contentDisposition = "form-data; name=\"filename = \"; filename=\"filename.jpg\"";
            Response.Headers.Add("Content-Disposition", contentDisposition);
            return Ok();
        }

        [HttpGet("/api/download/multipledelimeter")]
        public IActionResult MultipleDelimeter()
        {
            var contentDisposition = "form-data; name=\"filename = \"; filename=\"_NA__NA__; 2020-09.zip\"";
            Response.Headers.Add("Content-Disposition", contentDisposition);
            return Ok();
        }
    }
}
