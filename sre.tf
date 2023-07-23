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


resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
}

/*
# log based alert for VM stop
resource "google_monitoring_alert_policy" "instance_stopped_alert" {
  display_name = "Instance Stopped Alert"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Instance Stopped"
    condition_matched_log {
      filter = "resource.type=\"gce_instance\" protoPayload.methodName=\"v1.compute.instances.stop\""
      }
    }
     
  alert_strategy {
    notification_rate_limit {
      period     = "1800s"  # Example rate limit: one notification per 30 minutes
      }
    auto_close = "1800s"
    }
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]
}


# log based alert for VM delete
resource "google_monitoring_alert_policy" "instance_deleted_alert" {
  display_name = "Instance Deleted Alert"
  combiner     = "OR"
  enabled      = true
     
  conditions {
    display_name = "Instance Deleted"
    condition_matched_log {
      filter = "resource.type=\"gce_instance\" protoPayload.methodName=\"v1.compute.instances.delete\""
      }
    }
  alert_strategy {
    notification_rate_limit {
      period     = "1800s"  # Example rate limit: one notification per 5 minutes
      }
    auto_close = "1800s"
    }
  notification_channels = [google_monitoring_notification_channel.email_alerts.id]
}

*/

resource "google_logging_metric" "instance_stopped_metric" {
  name        = "Instance-Stopped-Metric"
  description = "Instance Stopped Metric"
  filter      = "resource.type=\"gce_instance\" AND protoPayload.methodName=\"v1.compute.instances.stop\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_logging_metric" "instance_delete_metric" {
  name        = "Instance-Delete-Metric"
  description = "Instance Delete Metric"
  filter      = "resource.type=\"gce_instance\" AND protoPayload.methodName=\"v1.compute.instances.delete\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "instance_stopped_alert" {
  display_name = "Instance Stopped Alert"
  combiner     = "OR"
  enabled      = true


  conditions {
    display_name = "Instance Stopped"
    condition_threshold {
      # In the below filter we used a custom log based metric named as instancestatuswhich we created from cloud console 'Log Based Metric" with Metric type as Counter, Units as 1, Filter selection as Project logs and Build filter = resource.type="gce_instance" protoPayload.methodName="v1.compute.instances.stop"

      filter     = "resource.type = \"gce_instance\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.instance_stopped_metric.name}\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_COUNT"
        cross_series_reducer = "REDUCE_COUNT"
        group_by_fields      = ["metadata.system_labels.name"]
      }
      threshold_value = 0.99 # Set the threshold value as per your requirement (e.g., 0.99 for 99% availability)
      trigger {
        count = 1
      }
    }
  }
  alert_strategy {
    auto_close = "1800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]
}

resource "google_monitoring_alert_policy" "instance_delete_alert" {
  display_name = "Instance Deleted Alert"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Instance Deleted"
    condition_threshold {
      # In the below filter we used a custom log based metric named as instancestatuswhich we created from cloud console 'Log Based Metric" with Metric type as Counter, Units as 1, Filter selection as Project logs and Build filter = resource.type="gce_instance" protoPayload.methodName="v1.compute.instances.stop"

      filter     = "resource.type = \"gce_instance\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.instance_delete_metric.name}\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_COUNT"
        cross_series_reducer = "REDUCE_COUNT"
        group_by_fields      = ["metadata.system_labels.name"]
      }
      threshold_value = 0.99 # Set the threshold value as per your requirement (e.g., 0.99 for 99% availability)
      trigger {
        count = 1
      }
    }
  }
  alert_strategy {
    auto_close = "1800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]
}
resource "google_monitoring_notification_channel" "email_alerts" {
  display_name = "Email Alerts"
  type         = "email"
  labels = {
    email_address = "suvendu-kumar.mishra@lloydsbanking.com" # Replace with your email address
  }
}
