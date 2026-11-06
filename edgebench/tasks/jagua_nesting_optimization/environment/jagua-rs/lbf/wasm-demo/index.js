import init, { initThreadPool, run_lbf_bpp_wasm, run_lbf_spp_wasm, init_logger_wasm} from "./pkg/lbf.js"; // Replace with actual wasm module name

async function loadJsonFromFileInput(fileInput) {
  return new Promise((resolve, reject) => {
    const file = fileInput.files[0];
    if (!file) {
      return reject("No file selected!");
    }
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const json = JSON.parse(reader.result);
        resolve(json);
      } catch (err) {
        reject(`Invalid JSON: ${err.message}`);
      }
    };
    reader.onerror = () => reject("File read error.");
    reader.readAsText(file);
  });
}

async function run() {
  await init();
  const threads = navigator.hardwareConcurrency || 4;
  await initThreadPool(threads);
  console.log(`>> Thread Pool initialized with ${threads} threads.`);
  init_logger_wasm();

  const resultBox = document.getElementById("result");
  const svgBox = document.getElementById("svgs");

  document.getElementById("reset-instance").onclick = () => {
    document.getElementById("instance-file").value = null;
    resultBox.textContent = "Instance input cleared.";
  };

  document.getElementById("reset-config").onclick = () => {
    document.getElementById("config-file").value = null;
    resultBox.textContent = "Config input cleared.";
  };

  document.getElementById("solve-btn").onclick = async () => {
    resultBox.textContent = "Running solver...";
    svgBox.innerHTML = "";

    const problemType = document.getElementById("problem-type").value;
    const instanceFileInput = document.getElementById("instance-file");
    const configFileInput = document.getElementById("config-file");

    let instance = null;
    let config = null;

    try {
      if (instanceFileInput.files.length > 0) {
        instance = await loadJsonFromFileInput(instanceFileInput);
      }

      if (configFileInput.files.length > 0) {
        config = await loadJsonFromFileInput(configFileInput);
      }

      // Build log BEFORE calling wasm
      const nullLog = `
  <b>Input Check:</b><br>
  Instance: ${instance ? "✅ Loaded" : "❌ Null"}<br>
  Config: ${config ? "✅ Loaded" : "❌ Null"}<br>
  Calling: <code>${
        problemType === "bpp" ? "run_lbf_bpp_wasm" : "run_lbf_spp_wasm"
      }</code><br><br>`;

      let result;
      if (problemType === "bpp") {
        result = await run_lbf_bpp_wasm(instance, config);
      } else if (problemType === "spp") {
        result = await run_lbf_spp_wasm(instance, config);
      } else {
        throw new Error("Unknown problem type.");
      }

      resultBox.innerHTML =
        nullLog +
        `<b>Solve time:</b> ${result.solve_time_ms} ms<br><pre>${JSON.stringify(
          result.output,
          null,
          2
        )}</pre>`;

      for (const [filename, svg] of result.svgs) {
        const div = document.createElement("div");
        div.innerHTML = `<h3>${filename}</h3>` + svg;
        svgBox.appendChild(div);
      }

    } catch (err) {
      // Still show nullLog on error
      const nullLog = `
  <b>Input Check:</b><br>
  Instance: ${instance ? "✅ Loaded" : "❌ Null"}<br>
  Config: ${config ? "✅ Loaded" : "❌ Null"}<br>
  Calling: <code>${
        problemType === "bpp" ? "run_lbf_bpp_wasm" : "run_lbf_spp_wasm"
      }</code><br><br>`;
      resultBox.innerHTML = nullLog + `<b style="color:red;">Error:</b> ${err}`;
      console.error(err);
    }
  };
}

run();
