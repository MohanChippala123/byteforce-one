/* Checklist progress + saved state. One board per page. */
(function () {
  var board = document.querySelector("[data-checklist]");
  if (!board) return;

  Array.prototype.forEach.call(document.querySelectorAll("details[data-script]"), function (details) {
    details.addEventListener("toggle", function () {
      if (!details.open || details.getAttribute("data-loaded")) return;
      details.setAttribute("data-loaded", "1");
      var code = details.querySelector("code");
      fetch(details.getAttribute("data-script"))
        .then(function (response) {
          if (!response.ok) throw new Error("request failed");
          return response.text();
        })
        .then(function (text) {
          code.textContent = text;
        })
        .catch(function () {
          code.textContent = "Could not load this script.";
        });
    });
  });

  var key = "byteforce:checklist:" + board.getAttribute("data-checklist");
  var boxes = Array.prototype.slice.call(board.querySelectorAll('input[type="checkbox"]'));
  var fill = document.querySelector("[data-progress]");
  var label = document.querySelector("[data-progress-label]");

  function read() {
    try {
      var saved = JSON.parse(localStorage.getItem(key));
      return Array.isArray(saved) ? saved : [];
    } catch (error) {
      return [];
    }
  }

  function save() {
    try {
      var done = boxes.filter(function (box) {
        return box.checked;
      }).map(function (box) {
        return box.id;
      });
      localStorage.setItem(key, JSON.stringify(done));
    } catch (error) {
      /* storage unavailable — checkboxes still work */
    }
  }

  function update() {
    var done = boxes.filter(function (box) {
      return box.checked;
    }).length;

    if (label) label.textContent = done + " / " + boxes.length;
    if (fill) fill.style.width = boxes.length ? (done / boxes.length) * 100 + "%" : "0%";
  }

  var saved = read();

  boxes.forEach(function (box) {
    box.checked = saved.indexOf(box.id) !== -1;
    box.addEventListener("change", function () {
      save();
      update();
    });
  });

  var reset = document.querySelector("[data-reset]");
  if (reset) {
    reset.addEventListener("click", function () {
      boxes.forEach(function (box) {
        box.checked = false;
      });
      save();
      update();
    });
  }

  var print = document.querySelector("[data-print]");
  if (print) {
    print.addEventListener("click", function () {
      window.print();
    });
  }

  update();
})();
