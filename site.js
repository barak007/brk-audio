(() => {
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const root = document.documentElement;
  const systemDark = window.matchMedia("(prefers-color-scheme: dark)");

  const reveal = (elements) => {
    if (!window.gsap || reducedMotion) return;
    window.gsap.fromTo(elements, { opacity: 0, y: 24 }, { opacity: 1, y: 0, duration: 0.72, stagger: 0.07, ease: "power3.out", clearProps: "transform" });
  };

  // Theme: the system's unless the header toggle stored a choice (applied before paint by the inline script in <head>).
  const isDark = () => (root.dataset.theme ? root.dataset.theme === "dark" : systemDark.matches);
  const themeToggle = document.querySelector(".theme-toggle");
  const labelThemeToggle = () => {
    if (!themeToggle) return;
    const next = isDark() ? "light" : "dark";
    themeToggle.textContent = next === "light" ? "Light" : "Dark";
    themeToggle.setAttribute("aria-label", `Switch to the ${next} theme`);
  };
  themeToggle?.addEventListener("click", () => {
    root.dataset.theme = isDark() ? "light" : "dark";
    try {
      localStorage.setItem("theme", root.dataset.theme);
    } catch {}
    labelThemeToggle();
    document.dispatchEvent(new Event("themechange"));
  });
  systemDark.addEventListener("change", () => {
    labelThemeToggle();
    document.dispatchEvent(new Event("themechange"));
  });
  labelThemeToggle();

  // Hero waves: one ribbon per colour in data-colors (the first leads) and a faint text-coloured line, each a
  // fundamental plus a drifting overtone. Every ribbon trails fading copies of where it was a few frames ago (with the
  // pointer as it was then), so the trails are exact and never leave residue. In the dark theme the ribbons glow and
  // add up where they cross. The pointer bends them; they stop drawing while the hero is off screen.
  const heroWaves = (canvas) => {
    const context = canvas.getContext("2d");
    const colorNames = (canvas.dataset.colors || "signal").split(" ").filter(Boolean);
    const shapes = [
      { frequency: 0.0031, speed: 0.021, amplitude: 0.17 },
      { frequency: 0.0046, speed: 0.029, amplitude: 0.12 },
      { frequency: 0.0038, speed: 0.016, amplitude: 0.15 },
      { frequency: 0.0052, speed: 0.034, amplitude: 0.1 }
    ];
    const trailLength = 12;
    const trailStep = 3;
    const pointer = { x: 0, y: 0, targetX: 0, targetY: 0 };
    const history = [];
    let ribbons = [];
    let neon = false;
    let width = 0;
    let height = 0;
    let time = 0;
    let frame = 0;

    const readTheme = () => {
      const styles = getComputedStyle(root);
      neon = styles.getPropertyValue("--waves").trim() === "neon";
      const colors = colorNames.map((name) => (name === "signal" ? styles.getPropertyValue("--signal").trim() : name));
      ribbons = [
        ...colors.map((color, index) => ({
          color,
          alpha: index === 0 ? 0.95 : 0.75,
          lineWidth: index === 0 ? 2 : 1.5,
          phase: index * 2.1,
          ...shapes[index % shapes.length]
        })),
        { color: styles.getPropertyValue("--text").trim(), alpha: neon ? 0.22 : 0.16, lineWidth: 1, frequency: 0.0022, speed: 0.012, amplitude: 0.21, phase: 1 }
      ];
    };

    const resize = () => {
      const scale = window.devicePixelRatio || 1;
      width = canvas.clientWidth;
      height = canvas.clientHeight;
      canvas.width = Math.max(1, Math.round(width * scale));
      canvas.height = Math.max(1, Math.round(height * scale));
      context.setTransform(scale, 0, 0, scale, 0, 0);
    };

    const stroke = (ribbon, at, bend, centre, scale, step) => {
      context.beginPath();
      for (let x = 0; x <= width + step; x += step) {
        const fundamental = Math.sin(x * ribbon.frequency + at * ribbon.speed + ribbon.phase + bend.x * 2);
        const overtone = Math.cos(x * ribbon.frequency * 2.2 - at * ribbon.speed * 1.4);
        const y = centre + (fundamental + overtone * 0.4) * ribbon.amplitude * scale + bend.y * scale * 0.45 * Math.sin(x * 0.003);
        if (x === 0) context.moveTo(x, y);
        else context.lineTo(x, y);
      }
      context.stroke();
    };

    const draw = () => {
      context.clearRect(0, 0, width, height);
      pointer.x += (pointer.targetX - pointer.x) * 0.05;
      pointer.y += (pointer.targetY - pointer.y) * 0.05;
      history.unshift({ x: pointer.x, y: pointer.y });
      history.length = Math.min(history.length, trailLength * trailStep + 1);

      const centre = height * (width < 900 ? 0.8 : 0.52);
      const scale = Math.min(height, 640) * (width < 900 ? 0.45 : 1);
      context.globalCompositeOperation = neon ? "lighter" : "source-over";

      for (const ribbon of ribbons) {
        context.strokeStyle = ribbon.color;
        context.shadowBlur = 0;
        context.lineWidth = 1;
        for (let echo = trailLength; echo >= 1; echo -= 1) {
          const fade = 1 - echo / (trailLength + 1);
          context.globalAlpha = ribbon.alpha * (neon ? 0.32 : 0.22) * fade * fade;
          const bend = history[Math.min(echo * trailStep, history.length - 1)];
          stroke(ribbon, time - echo * trailStep, bend, centre, scale, 6);
        }

        context.globalAlpha = ribbon.alpha;
        context.lineWidth = ribbon.lineWidth;
        context.shadowColor = ribbon.color;
        context.shadowBlur = neon ? 14 : 0;
        stroke(ribbon, time, history[0], centre, scale, 4);
      }

      context.globalAlpha = 1;
      context.shadowBlur = 0;
      context.globalCompositeOperation = "source-over";
    };

    const tick = () => {
      time += 1;
      draw();
      frame = requestAnimationFrame(tick);
    };

    readTheme();
    resize();
    document.addEventListener("themechange", () => {
      readTheme();
      draw();
    });
    new ResizeObserver(() => {
      resize();
      draw();
    }).observe(canvas);

    if (reducedMotion) {
      draw();
      return;
    }

    window.addEventListener("pointermove", (event) => {
      const bounds = canvas.getBoundingClientRect();
      pointer.targetX = (event.clientX - bounds.left) / bounds.width - 0.5;
      pointer.targetY = Math.max(-0.5, Math.min(0.5, (event.clientY - bounds.top) / bounds.height - 0.5));
    }, { passive: true });

    new IntersectionObserver(([entry]) => {
      cancelAnimationFrame(frame);
      if (entry.isIntersecting) frame = requestAnimationFrame(tick);
    }).observe(canvas);
  };

  // Terminal install: the format toggles rewrite the command (install.sh takes the formats as arguments; none means all
  // three), and each Copy button puts the command beside it on the clipboard. At least one format stays selected. The
  // install.sh URL is read from data-install on every update, because the version picker changes it.
  const installer = (container) => {
    const toggles = [...container.querySelectorAll(".install-format input")];
    const run = container.querySelector('[data-command="run"]');
    const read = container.querySelector('[data-command="read"]');
    const update = () => {
      const url = container.dataset.install;
      const chosen = toggles.filter((toggle) => toggle.checked).map((toggle) => toggle.value);
      const formats = chosen.length === toggles.length ? "" : ` ${chosen.join(" ")}`;
      run.textContent = `curl -fsSL ${url} | bash${formats && ` -s --${formats}`}`;
      read.textContent = `curl -fsSL ${url} -o install.sh && open -e install.sh`;
    };
    toggles.forEach((toggle) => toggle.addEventListener("change", () => {
      if (!toggles.some((other) => other.checked)) toggle.checked = true;
      update();
    }));
    container.addEventListener("releasechange", update);
    container.querySelectorAll(".install-copy").forEach((copy) => {
      const command = copy.parentElement.querySelector(".install-command");
      let restoreLabel = 0;
      copy.addEventListener("click", async () => {
        try {
          await navigator.clipboard.writeText(command.textContent);
          copy.textContent = "Copied";
        } catch {
          getSelection().selectAllChildren(command);
          copy.textContent = "Press ⌘C";
        }
        clearTimeout(restoreLabel);
        restoreLabel = setTimeout(() => (copy.textContent = "Copy"), 1600);
      });
      copy.hidden = false;
    });
    container.querySelector(".install-formats").hidden = false;
  };

  // Version picker: every released version is in its <option> (written at build time); picking one points the download
  // button, version label, install command and release links at that release.
  const versionPicker = (picker) => {
    const copy = picker.closest(".product-copy");
    const select = picker.querySelector("select");
    const install = copy.querySelector(".install");
    select.addEventListener("change", () => {
      const release = select.selectedOptions[0].dataset;
      copy.querySelector('[data-release="download"]').href = release.download;
      copy.querySelector('[data-release="version"]').textContent = release.version;
      if (!install) return;
      install.hidden = !release.install;
      install.dataset.install = release.install;
      install.querySelector('[data-release="install"]').href = release.install;
      install.querySelector('[data-release="page"]').href = release.page;
      install.dispatchEvent(new Event("releasechange"));
    });
    picker.hidden = false;
  };

  window.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll(".install[data-install]").forEach(installer);
    document.querySelectorAll(".version-picker").forEach(versionPicker);
    document.querySelectorAll(".hero-waves").forEach(heroWaves);
    reveal(document.querySelectorAll("main > .reveal, main > section > .reveal, .hero .reveal, .plugin-card.reveal"));
  });
})();
