resource "google_project_service" "logging" {
  project = var.project_id
  service = "logging.googleapis.com"
}

resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"
}

resource "google_project_service" "cloud_resource_manager" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "osconfig_api" {
  project = var.project_id
  service = "osconfig.googleapis.com"
}

/*
resource "google_logging_metric" "instance_uptime" {
  name        = "instance-uptime-metric"
  description = "Metric for instance uptime"
  filter      = "resource.type=\"gce_instance\" AND log_name=projects/${var.project_id}/logs/syslog AND textPayload:\"Stopped\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "instance_uptime_alert" {
  display_name = "Instance Uptime Alert"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Instance Uptime Condition"
    condition_threshold {
      filter           = "metric.type=\"logging.googleapis.com/user/instance-uptime-metric\" AND resource.type=gce_instance"
      duration         = "60s"
      comparison       = "COMPARISON_GT"
      threshold_value  = 0
      
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email_alerts.id
  ]
}
*/



resource "google_monitoring_alert_policy" "instance_alerts" {
  display_name            = "VM Resource Utilization Alert"
  combiner                = "OR"

  conditions {
    display_name = "Warning CPU Utilization"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85
    }
  }

  conditions {
    display_name = "Critical CPU Utilization"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.95
    }
  }

  conditions {
    display_name = "High Network Latency"
    condition_threshold {
      filter           = "metric.type=\"logging.googleapis.com/user/ICMPLatency\" AND resource.type=\"gce_instance\""
      duration         = "60s"
      comparison       = "COMPARISON_GT"
      threshold_value  = 20000
    }
  }
  

/*
  conditions {
    display_name = "Warning Memory Utilization"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/memory/usage\" resource.type=\"gce_instance\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85
    }
  }

  conditions {
    display_name = "Critical Memory Utilization"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/memory/usage\" resource.type=\"gce_instance\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.95
    }
  }
*/

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]
}

/*
# Create BQ Alerts
resource "google_monitoring_alert_policy" "bq_alerts" {
  display_name            = "Bigquery Alert"
  combiner                = "OR"

  conditions {
    display_name         = "BQ Quota Limit Condition"
    condition_threshold {
      comparison      = "COMPARISON_GT"
      duration        = "60s"
      filter          = "metric.type=\"bigquery.googleapis.com/quota/limit\" resource.type=\"bigquery_resource\""
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]
}
*/



#Create GCS Bucket Alerts
resource "google_monitoring_alert_policy" "gcs_usage_alert" {
  display_name = "GCS Bucket Usage Alert"
  combiner     = "OR"

    conditions {
      display_name         = "GCS Bucket Usage Condition"
      condition_threshold {
        comparison      = "COMPARISON_GT"
        duration        = "60s"
        filter          = "metric.type=\"storage.googleapis.com/storage/total_bytes\" resource.type=\"gcs_bucket\""
        threshold_value = 322122547200 # 300 GB in bytes
        aggregations {
          alignment_period = "60s"
          per_series_aligner = "ALIGN_SUM"
        }
      }
    }
    
    conditions {
    display_name      = "GCS Bucket UnAuthorised Access Attempt"
    condition_threshold {
      comparison      = "COMPARISON_GT"
      duration        = "60s"
      threshold_value = 1
      filter = "metric.type=\"storage.googleapis.com/api/request_count\" resource.type=\"gcs_bucket\" metric.label.\"response_code\"=\"PERMISSION_DENIED\"" 
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM"
        }
      trigger {
        count   = 1
        percent = 0
        }
      }
    }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]
}


# Create Cloud Monitoring Notification Channel (Email)
resource "google_monitoring_notification_channel" "email_alerts" {
  display_name = "Email Alerts"
  type         = "email"
  labels = {
    email_address = "klpshrwl@gmail.com"  # Replace with your email address
  }
}
