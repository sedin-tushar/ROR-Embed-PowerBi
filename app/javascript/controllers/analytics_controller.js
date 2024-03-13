import { Controller } from "@hotwired/stimulus";
import * as pbi from "powerbi-client";

export default class extends Controller {
  static targets = ["buttonGroup", "container", "embedButton", "loadingContainer"];

  connect() {
    this.state = {
      isEmbedButtonClicked: false,
      selectedReport: null,
    };

    this.embedButtonTarget.addEventListener("click", () => {
      if (!this.state.isEmbedButtonClicked) {
        this.state.isEmbedButtonClicked = true;
        this.loadingContainerTarget.style.display = "block";
        fetch("/load-embed-config")
          .then(response => response.json())
          .then(embedConfigs => {
            this.loadingContainerTarget.style.display = "none";
            this.buttonGroupTarget.innerHTML = "";
            embedConfigs.forEach(embedConfig => {
              const button = document.createElement("button");
              button.textContent = embedConfig.report_config.reportName;
              button.dataset.reportId = embedConfig.report_config.reportId;
              button.addEventListener("click", () => this.selectReport(embedConfig.report_config, button));
              this.buttonGroupTarget.appendChild(button);
            });
            this.buttonGroupTarget.style.display = "block";
          });
      }
      if (this.state.isEmbedButtonClicked) {
        this.embedButtonTarget.style.backgroundColor = "red";
        this.embedButtonTarget.style.color = "white"; 
      }
    });
  }


  selectReport(reportConfig, button) {
    if (this.state.selectedReport) {
      this.state.selectedReport.button.style.backgroundColor = "";
      this.state.selectedReport.button.style.color = "";
    }

    button.style.backgroundColor = "black";
    button.style.color = "white";
    this.state.selectedReport = {
      reportConfig: reportConfig,
      button: button,
    };
    this.loadReport(reportConfig);
  }

  loadReport(reportConfig) {
    this.containerTarget.innerHTML = "";
    const reportContainer = document.createElement("div");
    reportContainer.classList.add("powerbi-report-container");
    this.containerTarget.appendChild(reportContainer);

    const reportLoadConfig = {
      type: "report",
      tokenType: pbi.models.TokenType.Embed,
      accessToken: reportConfig.embedToken,
      embedUrl: reportConfig.embedUrl,
    };

    powerbi.embed(reportContainer, reportLoadConfig);
  }
}

