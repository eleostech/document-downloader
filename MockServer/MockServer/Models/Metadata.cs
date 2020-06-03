using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MockServer;

namespace MockServer.Models { 
    public partial class Metadata
    {
        [JsonProperty("sent_to_email")]
        public string SentToEmail { get; set; }

        [JsonProperty("document_identifier")]
        public long DocumentIdentifier { get; set; }

        [JsonProperty("number_of_pages")]
        public long NumberOfPages { get; set; }

        [JsonProperty("custom_metadata")]
        public CustomMetadata CustomMetadata { get; set; }

        [JsonProperty("scanned_by_email")]
        public string ScannedByEmail { get; set; }

        [JsonProperty("download_url")]
        public Uri DownloadUrl { get; set; }

        [JsonProperty("scanned_by_username")]
        public string ScannedByUsername { get; set; }

        [JsonProperty("scanned_by")]
        public string ScannedBy { get; set; }

        [JsonProperty("upload_finished_at")]
        public DateTimeOffset UploadFinishedAt { get; set; }

        [JsonProperty("bill_of_lading_number")]
        public string BillOfLadingNumber { get; set; }

        [JsonProperty("load_number")]
        public string LoadNumber { get; set; }

        [JsonProperty("document_types")]
        public string[] DocumentTypes { get; set; }
    }

    public partial class CustomMetadata
    {
        [JsonProperty("YOUR-FIELD")]
        public string YourField { get; set; }
    }
}
