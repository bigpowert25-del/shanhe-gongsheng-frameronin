(() => {
  "use strict";

  const $ = (id) => document.getElementById(id);
  const canvas = $("stage");
  const ctx = canvas.getContext("2d", { alpha: false });
  const gameRoot = $("game");
  const panel = $("panel");
  const hud = $("hud");
  const missions = $("missions");
  const controls = $("touch-controls");
  const toastNode = $("toast");
  const loading = $("loading");
  const loadingBar = $("loading-bar");
  const loadingDetail = $("loading-detail");
  const healthBar = $("health-bar");
  const energyBar = $("energy-bar");
  const healthNumber = $("health-number");
  const energyNumber = $("energy-number");
  const chapterKicker = $("chapter-kicker");
  const chapterName = $("chapter-name");

  const images = new Map();
  const keys = new Set();
  const joystick = { x: 0, y: 0, pointerId: null };
  const rows = { idle: 0, walk: 1, attack: 2, hurt: 3 };
  const chapterActor = ["ayan", "shenjin", "qiaosheng", "ayan", "shenjin", "boss_06"];
  const saveKey = "shanhe-lite-save-v1";

  let content = null;
  let world = null;
  let currentBackground = "assets/backgrounds/cover.webp";
  let lastTime = performance.now();
  let elapsed = 0;
  let toastTimer = 0;
  let uiLocked = false;
  let hudVisible = true;

  const state = {
    screen: "boot",
    chapterIndex: 0,
    selectedTraits: [],
    stats: { ink: 45, heart: 45, fate: 45, hero: 0, people: 0 },
    fragments: [],
  };

  const particles = Array.from({ length: 58 }, (_, index) => ({
    x: (index * 223 + 91) % 1280,
    y: (index * 137 + 47) % 720,
    speed: 7 + (index % 9) * 2.2,
    size: 1 + (index % 4) * 0.55,
    phase: index * 0.73,
  }));

  function escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }

  function cnNumber(value) {
    return ["零", "一", "二", "三", "四", "五", "六"][Math.max(0, Math.min(6, value))];
  }

  function actorIdFor(value) {
    return value === "moyan" ? "boss_06" : value;
  }

  function backgroundFor(index) {
    return `assets/backgrounds/chapter_${String(index + 1).padStart(2, "0")}.webp`;
  }

  function actorUrl(id) {
    return `assets/actors/${actorIdFor(id)}.webp`;
  }

  function portraitUrl(id) {
    return `assets/portraits/${id === "boss_06" ? "moyan" : id}.webp`;
  }

  function fullGameUrl() {
    return location.hostname.endsWith("github.io") ? "../" : "/shanhe-godot/";
  }

  function imageFromCache(url) {
    return images.get(url) || null;
  }

  function loadImage(url) {
    if (images.has(url)) return Promise.resolve(images.get(url));
    return new Promise((resolve, reject) => {
      const image = new Image();
      image.decoding = "async";
      image.onload = () => {
        images.set(url, image);
        resolve(image);
      };
      image.onerror = () => reject(new Error(`无法加载 ${url}`));
      image.src = url;
    });
  }

  async function loadBundle(urls, title = "正在展开画卷") {
    loading.classList.remove("hidden");
    $("loading-title").textContent = title;
    loadingBar.style.width = "0%";
    let loaded = 0;
    const unique = [...new Set(urls)];
    await Promise.all(unique.map(async (url) => {
      await loadImage(url);
      loaded += 1;
      const progress = Math.round((loaded / unique.length) * 100);
      loadingBar.style.width = `${progress}%`;
      loadingDetail.textContent = `轻量资源 ${loaded} / ${unique.length}`;
    }));
    loading.classList.add("hidden");
  }

  function setPanel(html) {
    panel.innerHTML = html;
  }

  function clearPanel() {
    panel.innerHTML = "";
  }

  function setGameplayUi(enabled) {
    hud.classList.toggle("hidden", !enabled);
    missions.classList.toggle("hidden", !enabled || !hudVisible);
    controls.classList.toggle("hidden", !enabled);
  }

  function showToast(message) {
    toastNode.textContent = message;
    toastNode.classList.add("show");
    window.clearTimeout(toastTimer);
    toastTimer = window.setTimeout(() => toastNode.classList.remove("show"), 2100);
  }

  function requestImmersive() {
    if (gameRoot.requestFullscreen && !document.fullscreenElement) {
      gameRoot.requestFullscreen().catch(() => {});
    }
    if (screen.orientation?.lock) {
      screen.orientation.lock("landscape").catch(() => {});
    }
  }

  function resetState() {
    state.chapterIndex = 0;
    state.selectedTraits = [];
    state.stats = { ink: 45, heart: 45, fate: 45, hero: 0, people: 0 };
    state.fragments = [];
    localStorage.removeItem(saveKey);
  }

  function saveProgress() {
    localStorage.setItem(saveKey, JSON.stringify({
      chapterIndex: state.chapterIndex,
      selectedTraits: state.selectedTraits,
      stats: state.stats,
      fragments: state.fragments,
    }));
  }

  function loadProgress() {
    try {
      const saved = JSON.parse(localStorage.getItem(saveKey) || "null");
      if (!saved || !Array.isArray(saved.selectedTraits)) return false;
      state.chapterIndex = Math.max(0, Math.min(5, Number(saved.chapterIndex) || 0));
      state.selectedTraits = saved.selectedTraits.slice(0, 2);
      state.stats = { ...state.stats, ...(saved.stats || {}) };
      state.fragments = Array.isArray(saved.fragments) ? saved.fragments : [];
      return state.selectedTraits.length === 2;
    } catch {
      return false;
    }
  }

  function showTitle() {
    state.screen = "title";
    uiLocked = true;
    currentBackground = "assets/backgrounds/cover.webp";
    setGameplayUi(false);
    const canResume = Boolean(localStorage.getItem(saveKey));
    setPanel(`
      <article class="panel-card title-card">
        <div class="eyebrow">守卷任务 · 轻量网页版</div>
        <h1>画境装配局</h1>
        <h2>山 河 共 生</h2>
        <p>选取两种共生能力，进入六幅古画。与人物交谈、收集记忆、修复阵眼，在墨刃交锋后决定他们的历史由谁书写。</p>
        <div class="button-row">
          <button class="primary-button" id="new-game" type="button">新建守卷人</button>
          ${canResume ? '<button class="secondary-button" id="resume-game" type="button">继续上次任务</button>' : ""}
          <a class="secondary-button" href="${fullGameUrl()}" style="display:grid;place-items:center;text-decoration:none">电脑完整画质版</a>
        </div>
      </article>
    `);
    $("new-game").addEventListener("click", () => {
      requestImmersive();
      resetState();
      showTraitLab();
    });
    if ($("resume-game")) {
      $("resume-game").addEventListener("click", () => {
        requestImmersive();
        if (loadProgress()) beginChapter();
        else showTraitLab();
      });
    }
  }

  function showTraitLab() {
    state.screen = "lab";
    uiLocked = true;
    setGameplayUi(false);
    renderTraitLab();
  }

  function renderTraitLab() {
    const cards = content.traits.map((trait) => {
      const selected = state.selectedTraits.includes(trait.id);
      return `
        <button class="trait-card ${selected ? "selected" : ""}" data-trait="${escapeHtml(trait.id)}" type="button">
          <strong>${escapeHtml(trait.name)}</strong>
          <small>${escapeHtml(trait.origin)}</small>
          <span>${escapeHtml(trait.desc)}</span>
        </button>
      `;
    }).join("");
    setPanel(`
      <article class="panel-card lab-card">
        <div class="lab-head">
          <div>
            <div class="eyebrow">共生装配室</div>
            <h2>选择两种共生能力</h2>
          </div>
          <p>能力会改变移动、攻击、生命与修复效率。手机端已采用逐章加载，不会一次下载全部六卷。</p>
        </div>
        <div class="trait-grid">${cards}</div>
        <div class="lab-footer">
          <span>已装配 ${state.selectedTraits.length} / 2</span>
          <button class="primary-button" id="enter-scroll" type="button" ${state.selectedTraits.length === 2 ? "" : "disabled"}>进入第一卷</button>
        </div>
      </article>
    `);
    panel.querySelectorAll("[data-trait]").forEach((button) => {
      button.addEventListener("click", () => {
        const id = button.dataset.trait;
        const existing = state.selectedTraits.indexOf(id);
        if (existing >= 0) state.selectedTraits.splice(existing, 1);
        else if (state.selectedTraits.length < 2) state.selectedTraits.push(id);
        else showToast("只能装配两种能力");
        renderTraitLab();
      });
    });
    $("enter-scroll").addEventListener("click", () => {
      if (state.selectedTraits.length === 2) beginChapter();
    });
  }

  async function beginChapter() {
    const chapter = content.chapters[state.chapterIndex];
    const npcId = actorIdFor(chapter.npc.id);
    const bossId = `boss_${String(state.chapterIndex + 1).padStart(2, "0")}`;
    currentBackground = backgroundFor(state.chapterIndex);
    setPanel("");
    uiLocked = true;
    await loadBundle([
      currentBackground,
      actorUrl("you"),
      actorUrl("rift_walker"),
      actorUrl(npcId),
      actorUrl(bossId),
    ], `正在展开第${cnNumber(state.chapterIndex + 1)}卷`);
    showDialogue(chapter.intro, 0, startExploration);
  }

  function showDialogue(lines, index, onComplete, heading = null) {
    state.screen = "dialogue";
    uiLocked = true;
    setGameplayUi(false);
    if (index >= lines.length) {
      clearPanel();
      onComplete();
      return;
    }
    const line = lines[index];
    const portrait = portraitUrl(line.id);
    setPanel(`
      <article class="panel-card dialogue-card">
        <div class="dialogue-copy">
          <small>${escapeHtml(heading || content.chapters[state.chapterIndex].subtitle)}</small>
          <h2>${escapeHtml(line.speaker)}</h2>
          <p>${escapeHtml(line.text)}</p>
          <button class="primary-button" id="next-line" type="button">${index === lines.length - 1 ? "进入画境" : "继续"}</button>
        </div>
        <div class="dialogue-portrait" id="dialogue-portrait"></div>
      </article>
    `);
    loadImage(portrait).then(() => {
      const node = $("dialogue-portrait");
      if (node) node.style.backgroundImage = `url("${portrait}")`;
    }).catch(() => {});
    $("next-line").addEventListener("click", () => showDialogue(lines, index + 1, onComplete, heading));
  }

  function selected(id) {
    return state.selectedTraits.includes(id);
  }

  function makeWorld() {
    const chapter = content.chapters[state.chapterIndex];
    const maxHealth = selected("bear") ? 150 : 110;
    return {
      player: {
        x: 300,
        y: 565,
        vx: 0,
        vy: 0,
        facing: 1,
        hp: maxHealth,
        maxHp: maxHealth,
        energy: selected("horse") ? 125 : 100,
        maxEnergy: selected("horse") ? 125 : 100,
        attackCooldown: 0,
        dashCooldown: 0,
        dashTime: 0,
        attackFx: 0,
        hurtFx: 0,
      },
      npc: {
        x: Math.min(965, Number(chapter.npc.pos.x)),
        y: Math.min(455, Number(chapter.npc.pos.y)),
        id: actorIdFor(chapter.npc.id),
      },
      npcTalked: false,
      fragments: [
        { x: 535, y: 185, done: false },
        { x: 760, y: 315, done: false },
        { x: 915, y: 565, done: false },
      ],
      seals: [
        { x: 495, y: 395, done: false },
        { x: 840, y: 190, done: false },
      ],
      lore: [
        { x: 690, y: 570, done: false, index: 0 },
        { x: 1080, y: 325, done: false, index: 1 },
      ],
      enemies: [
        { x: 420, y: 235, hp: 76, maxHp: 76, cooldown: 0, facing: -1, dead: false },
        { x: 665, y: 445, hp: 76, maxHp: 76, cooldown: 0, facing: -1, dead: false },
        { x: 920, y: 245, hp: 76, maxHp: 76, cooldown: 0, facing: -1, dead: false },
        { x: 900, y: 590, hp: 76, maxHp: 76, cooldown: 0, facing: -1, dead: false },
      ],
      boss: null,
      bossDefeated: false,
      enemiesDefeated: 0,
    };
  }

  function startExploration() {
    state.screen = "explore";
    uiLocked = false;
    world = makeWorld();
    setGameplayUi(true);
    const chapter = content.chapters[state.chapterIndex];
    chapterKicker.textContent = `第${cnNumber(state.chapterIndex + 1)}卷`;
    chapterName.textContent = chapter.title;
    updateHud();
    showToast("先与画中人物交谈，再完成修复与讨伐");
  }

  function distance(a, b) {
    return Math.hypot(a.x - b.x, a.y - b.y);
  }

  function normalize(x, y) {
    const length = Math.hypot(x, y);
    return length > 0.001 ? { x: x / length, y: y / length } : { x: 0, y: 0 };
  }

  function update(delta) {
    if (state.screen !== "explore" || uiLocked || !world) return;
    const player = world.player;
    player.attackCooldown = Math.max(0, player.attackCooldown - delta);
    player.dashCooldown = Math.max(0, player.dashCooldown - delta);
    player.dashTime = Math.max(0, player.dashTime - delta);
    player.attackFx = Math.max(0, player.attackFx - delta);
    player.hurtFx = Math.max(0, player.hurtFx - delta);
    player.energy = Math.min(player.maxEnergy, player.energy + delta * 8);

    let moveX = joystick.x;
    let moveY = joystick.y;
    if (keys.has("a") || keys.has("arrowleft")) moveX -= 1;
    if (keys.has("d") || keys.has("arrowright")) moveX += 1;
    if (keys.has("w") || keys.has("arrowup")) moveY -= 1;
    if (keys.has("s") || keys.has("arrowdown")) moveY += 1;
    const move = normalize(moveX, moveY);
    player.vx = move.x;
    player.vy = move.y;
    if (Math.abs(move.x) > 0.1) player.facing = Math.sign(move.x);
    const speed = (selected("horse") ? 248 : 210) * (player.dashTime > 0 ? 2.3 : 1);
    player.x = Math.max(95, Math.min(1185, player.x + move.x * speed * delta));
    player.y = Math.max(105, Math.min(650, player.y + move.y * speed * delta));

    for (const enemy of world.enemies) {
      if (enemy.dead) continue;
      enemy.cooldown = Math.max(0, enemy.cooldown - delta);
      const direction = normalize(player.x - enemy.x, player.y - enemy.y);
      const gap = distance(player, enemy);
      enemy.facing = direction.x >= 0 ? 1 : -1;
      if (gap > 68) {
        enemy.x += direction.x * 74 * delta;
        enemy.y += direction.y * 74 * delta;
      } else if (enemy.cooldown <= 0 && player.dashTime <= 0) {
        hurtPlayer(8);
        enemy.cooldown = 1.05;
      }
    }

    if (world.boss && !world.boss.dead) {
      const boss = world.boss;
      boss.cooldown = Math.max(0, boss.cooldown - delta);
      const direction = normalize(player.x - boss.x, player.y - boss.y);
      const gap = distance(player, boss);
      boss.facing = direction.x >= 0 ? 1 : -1;
      if (gap > 92) {
        boss.x += direction.x * 62 * delta;
        boss.y += direction.y * 62 * delta;
      } else if (boss.cooldown <= 0 && player.dashTime <= 0) {
        hurtPlayer(15);
        boss.cooldown = .9;
      }
    }

    maybeSpawnBoss();
    updateHud();
  }

  function hurtPlayer(amount) {
    const player = world.player;
    const reduced = selected("bear") ? amount * .68 : amount;
    player.hp = Math.max(0, player.hp - reduced);
    player.hurtFx = .22;
    if (player.hp <= 0) {
      player.hp = player.maxHp;
      player.energy = player.maxEnergy * .55;
      player.x = 300;
      player.y = 565;
      state.stats.fate = Math.max(0, state.stats.fate - 2);
      showToast("守卷印将你拉回画境入口");
    }
  }

  function damageTargets(radius, baseDamage) {
    const player = world.player;
    let damage = selected("tiger") ? baseDamage * 1.4 : baseDamage;
    if (selected("eagle") && Math.random() < .34) damage *= 1.75;
    let hits = 0;
    for (const enemy of world.enemies) {
      if (enemy.dead || distance(player, enemy) > radius) continue;
      enemy.hp -= damage;
      hits += 1;
      if (enemy.hp <= 0) {
        enemy.dead = true;
        world.enemiesDefeated += 1;
        state.stats.hero += 1;
      }
    }
    if (world.boss && !world.boss.dead && distance(player, world.boss) <= radius + 24) {
      world.boss.hp -= damage;
      hits += 1;
      if (world.boss.hp <= 0) {
        world.boss.dead = true;
        world.bossDefeated = true;
        state.stats.hero += 6;
        window.setTimeout(showDecision, 650);
      }
    }
    if (selected("wolf") && hits > 0) {
      player.hp = Math.min(player.maxHp, player.hp + hits * 3.5);
    }
    return hits;
  }

  function attack() {
    if (state.screen !== "explore" || uiLocked || !world) return;
    const player = world.player;
    if (player.attackCooldown > 0) return;
    player.attackCooldown = selected("tiger") ? .22 : .31;
    player.attackFx = .19;
    const radius = selected("eagle") ? 166 : 128;
    damageTargets(radius, 38);
    maybeSpawnBoss();
  }

  function burst() {
    if (state.screen !== "explore" || uiLocked || !world) return;
    const player = world.player;
    const cost = selected("chimp") ? 24 : 34;
    if (player.energy < cost) {
      showToast("共鸣尚未恢复");
      return;
    }
    player.energy -= cost;
    player.attackFx = .38;
    const hits = damageTargets(285, 68);
    showToast(hits ? `共鸣命中 ${hits} 个目标` : "共鸣照亮了附近的墨痕");
    maybeSpawnBoss();
  }

  function dash() {
    if (state.screen !== "explore" || uiLocked || !world) return;
    const player = world.player;
    if (player.dashCooldown > 0 || player.energy < 8) return;
    let direction = normalize(player.vx, player.vy);
    if (!direction.x && !direction.y) direction = { x: player.facing, y: 0 };
    player.x = Math.max(95, Math.min(1185, player.x + direction.x * 118));
    player.y = Math.max(105, Math.min(650, player.y + direction.y * 118));
    player.energy -= 8;
    player.dashTime = .25;
    player.dashCooldown = selected("tiger") ? .42 : .66;
  }

  function nearestPending(items, range) {
    let result = null;
    let best = range;
    for (const item of items) {
      if (item.done) continue;
      const gap = distance(world.player, item);
      if (gap < best) {
        result = item;
        best = gap;
      }
    }
    return result;
  }

  function interact() {
    if (state.screen !== "explore" || uiLocked || !world) return;
    const chapter = content.chapters[state.chapterIndex];
    if (!world.npcTalked && distance(world.player, world.npc) < 115) {
      world.npcTalked = true;
      state.stats.people += 2;
      const lines = chapter.npc.lines.map((text) => ({ id: chapter.npc.id, speaker: chapter.npc.name, text }));
      showDialogue(lines, 0, () => {
        state.screen = "explore";
        uiLocked = false;
        setGameplayUi(true);
        maybeSpawnBoss();
      }, chapter.npc.title);
      return;
    }
    const fragment = nearestPending(world.fragments, 82);
    if (fragment) {
      fragment.done = true;
      showToast(`记忆残片 ${world.fragments.filter((item) => item.done).length} / 3`);
      maybeSpawnBoss();
      return;
    }
    const seal = nearestPending(world.seals, 90);
    if (seal) {
      seal.done = true;
      showToast(`阵眼修复 ${world.seals.filter((item) => item.done).length} / 2`);
      maybeSpawnBoss();
      return;
    }
    const lore = nearestPending(world.lore, 90);
    if (lore) {
      lore.done = true;
      state.stats.people += 3;
      const entry = chapter.lore[lore.index];
      uiLocked = true;
      setPanel(`
        <article class="panel-card dialogue-card">
          <div class="dialogue-copy">
            <small>人文见闻 · 可选任务</small>
            <h2>${escapeHtml(entry.title)}</h2>
            <p>${escapeHtml(entry.text)}</p>
            <button class="primary-button" id="close-lore" type="button">收入守卷录</button>
          </div>
          <div class="dialogue-portrait" style="background-image:url('${currentBackground}');filter:sepia(.25) saturate(.62)"></div>
        </article>
      `);
      $("close-lore").addEventListener("click", () => {
        clearPanel();
        uiLocked = false;
        state.screen = "explore";
      });
      return;
    }
    showToast("附近没有可交互目标");
  }

  function objectiveReady() {
    return world.npcTalked
      && world.fragments.every((item) => item.done)
      && world.seals.every((item) => item.done)
      && world.enemiesDefeated >= world.enemies.length;
  }

  function maybeSpawnBoss() {
    if (!world || world.boss || world.bossDefeated || !objectiveReady()) return;
    world.boss = {
      x: 865,
      y: 350,
      hp: 260 + state.chapterIndex * 32,
      maxHp: 260 + state.chapterIndex * 32,
      cooldown: .8,
      facing: -1,
      dead: false,
    };
    showToast(`${content.chapters[state.chapterIndex].boss} 已显形`);
  }

  function updateHud() {
    if (!world) return;
    const player = world.player;
    healthNumber.textContent = Math.ceil(player.hp);
    energyNumber.textContent = Math.ceil(player.energy);
    healthBar.style.width = `${Math.max(0, (player.hp / player.maxHp) * 100)}%`;
    energyBar.style.width = `${Math.max(0, (player.energy / player.maxEnergy) * 100)}%`;
    const done = (value) => value ? "done" : "";
    missions.innerHTML = `
      <strong>本卷任务</strong>
      <div class="${done(world.npcTalked)}">○ 与画中人物交谈</div>
      <div class="${done(world.fragments.every((item) => item.done))}">◇ 记忆残片 ${world.fragments.filter((item) => item.done).length} / 3</div>
      <div class="${done(world.seals.every((item) => item.done))}">◎ 修复阵眼 ${world.seals.filter((item) => item.done).length} / 2</div>
      <div class="${done(world.enemiesDefeated >= 4)}">╱ 清除裂墨 ${world.enemiesDefeated} / 4</div>
      <div class="${done(world.bossDefeated)}">◆ ${world.boss ? "击败" : "等待"}守卷首领</div>
      <div>⌁ 人文见闻 ${world.lore.filter((item) => item.done).length} / 2</div>
    `;
  }

  function showDecision() {
    if (state.screen === "decision") return;
    state.screen = "decision";
    uiLocked = true;
    setGameplayUi(false);
    const chapter = content.chapters[state.chapterIndex];
    setPanel(`
      <article class="panel-card decision-card">
        <div class="eyebrow">首领已退 · 历史仍未落笔</div>
        <h2>${escapeHtml(chapter.title)}之后</h2>
        <div class="choice-grid">
          ${chapter.choices.map((choice, index) => `
            <button class="choice-card" data-choice="${index}" type="button">
              <strong>${escapeHtml(choice.title)}</strong>
              <span>${escapeHtml(choice.desc)}</span>
              <small>${escapeHtml(choice.fragment)}</small>
            </button>
          `).join("")}
        </div>
      </article>
    `);
    panel.querySelectorAll("[data-choice]").forEach((button) => {
      button.addEventListener("click", () => applyChoice(Number(button.dataset.choice)));
    });
  }

  function applyChoice(index) {
    const chapter = content.chapters[state.chapterIndex];
    const choice = chapter.choices[index];
    for (const [key, value] of Object.entries(choice.delta || {})) {
      state.stats[key] = Number(state.stats[key] || 0) + Number(value);
    }
    state.fragments.push(choice.fragment);
    state.chapterIndex += 1;
    saveProgress();
    setPanel(`
      <article class="panel-card dialogue-card">
        <div class="dialogue-copy">
          <small>守卷记录 · ${escapeHtml(choice.fragment)}</small>
          <h2>${escapeHtml(choice.title)}</h2>
          <p>${escapeHtml(choice.result)}</p>
          <button class="primary-button" id="next-chapter" type="button">${state.chapterIndex >= content.chapters.length ? "查看山河结局" : `进入第${cnNumber(state.chapterIndex + 1)}卷`}</button>
        </div>
        <div class="dialogue-portrait" style="background-image:url('${currentBackground}')"></div>
      </article>
    `);
    $("next-chapter").addEventListener("click", () => {
      if (state.chapterIndex >= content.chapters.length) showEnding();
      else beginChapter();
    });
  }

  function showEnding() {
    state.screen = "ending";
    currentBackground = "assets/backgrounds/epilogue.webp";
    loadImage(currentBackground).catch(() => {});
    localStorage.removeItem(saveKey);
    let title = "未完山河";
    let text = "你没有替所有人落下最后一笔。山河卷从此允许每位来者留下自己的路，而守卷人的职责变成倾听。";
    if (state.stats.heart > state.stats.ink + 8) {
      title = "众生新卷";
      text = "画中人获得昼夜、衰老与真正的明天。英雄气不再属于一位守卷人，而属于每个仍愿意替别人留灯的人。";
    } else if (state.stats.ink > state.stats.heart + 12) {
      title = "有门之卷";
      text = "山河恢复秩序，却保留了一扇通往画外的门。你守住原作，也承认原作不能成为囚笼。";
    }
    setPanel(`
      <article class="panel-card title-card">
        <div class="eyebrow">山河共生 · 结局</div>
        <h1>${escapeHtml(title)}</h1>
        <p>${escapeHtml(text)}</p>
        <p>墨韵 ${state.stats.ink} · 心火 ${state.stats.heart} · 命数 ${state.stats.fate} · 英雄气 ${state.stats.hero} · 民声 ${state.stats.people}</p>
        <div class="button-row">
          <button class="primary-button" id="restart" type="button">重新入画</button>
          <button class="secondary-button" id="back-title" type="button">返回卷首</button>
        </div>
      </article>
    `);
    $("restart").addEventListener("click", () => {
      resetState();
      showTraitLab();
    });
    $("back-title").addEventListener("click", showTitle);
  }

  function drawCover(image) {
    if (image) ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
    else {
      ctx.fillStyle = "#342a1d";
      ctx.fillRect(0, 0, canvas.width, canvas.height);
    }
    ctx.fillStyle = state.screen === "explore" ? "rgba(28,15,8,.22)" : "rgba(5,9,7,.46)";
    ctx.fillRect(0, 0, canvas.width, canvas.height);
  }

  function drawParticles() {
    const chapter = content?.chapters?.[Math.min(state.chapterIndex, 5)];
    const accent = chapter?.accent || "#d7b36b";
    ctx.save();
    ctx.fillStyle = accent;
    for (const particle of particles) {
      let y = (particle.y + elapsed * particle.speed) % 760 - 20;
      let x = particle.x + Math.sin(elapsed * .32 + particle.phase) * 18;
      ctx.globalAlpha = .12 + (Math.sin(elapsed + particle.phase) + 1) * .07;
      ctx.beginPath();
      ctx.arc(x, y, particle.size, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.restore();
  }

  function drawMarker(item, kind) {
    if (item.done) return;
    ctx.save();
    ctx.translate(item.x, item.y);
    if (kind === "fragment") {
      ctx.rotate(Math.sin(elapsed * 1.4 + item.x) * .08);
      ctx.fillStyle = "rgba(224,208,169,.88)";
      ctx.fillRect(-12, -16, 24, 32);
      ctx.strokeStyle = "rgba(103,65,47,.72)";
      ctx.lineWidth = 2;
      ctx.strokeRect(-12, -16, 24, 32);
      ctx.beginPath();
      ctx.moveTo(-6, -6);
      ctx.lineTo(7, -6);
      ctx.moveTo(-6, 1);
      ctx.lineTo(5, 1);
      ctx.stroke();
    } else if (kind === "seal") {
      ctx.strokeStyle = "rgba(190,84,64,.82)";
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(0, 0, 32 + Math.sin(elapsed * 2) * 2, 0, Math.PI * 2);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(-12, 0);
      ctx.lineTo(0, -15);
      ctx.lineTo(12, 0);
      ctx.lineTo(0, 15);
      ctx.closePath();
      ctx.stroke();
    } else {
      ctx.fillStyle = "rgba(24,34,30,.86)";
      ctx.strokeStyle = "rgba(215,179,107,.72)";
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(0, 0, 20, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = "#d8c79f";
      ctx.font = "18px serif";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText("文", 0, 1);
    }
    ctx.restore();
  }

  function drawActor(id, x, y, motion, scale, facing = 1, hp = null, maxHp = null, label = "") {
    const image = imageFromCache(actorUrl(id));
    const row = rows[motion] ?? 0;
    const frame = Math.floor(elapsed * (motion === "attack" ? 12 : motion === "walk" ? 8 : 5)) % 4;
    const frameWidth = 192;
    const frameHeight = 288;
    const width = frameWidth * scale;
    const height = frameHeight * scale;
    ctx.save();
    ctx.translate(x, y);
    ctx.scale(facing, 1);
    if (image) {
      ctx.drawImage(
        image,
        frame * frameWidth,
        row * frameHeight,
        frameWidth,
        frameHeight,
        -width / 2,
        -height,
        width,
        height,
      );
    } else {
      ctx.fillStyle = "rgba(18,25,22,.92)";
      ctx.beginPath();
      ctx.ellipse(0, -height * .42, width * .28, height * .48, 0, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.restore();
    if (hp !== null && maxHp) {
      ctx.fillStyle = "rgba(8,10,9,.72)";
      ctx.fillRect(x - 27, y - height - 12, 54, 4);
      ctx.fillStyle = id.startsWith("boss_") ? "#d5a358" : "#c77a67";
      ctx.fillRect(x - 27, y - height - 12, 54 * Math.max(0, hp / maxHp), 4);
    }
    if (label) {
      ctx.font = "13px 'PingFang SC', sans-serif";
      ctx.textAlign = "center";
      ctx.fillStyle = "#e5dcc7";
      ctx.fillText(label, x, y + 17);
    }
  }

  function drawWorld() {
    if (!world) return;
    for (const item of world.fragments) drawMarker(item, "fragment");
    for (const item of world.seals) drawMarker(item, "seal");
    for (const item of world.lore) drawMarker(item, "lore");

    const chapter = content.chapters[state.chapterIndex];
    const actors = [];
    actors.push({
      id: world.npc.id,
      x: world.npc.x,
      y: world.npc.y,
      motion: "idle",
      scale: .43,
      facing: -1,
      label: chapter.npc.name,
    });
    for (const enemy of world.enemies) {
      if (enemy.dead) continue;
      actors.push({
        id: "rift_walker",
        x: enemy.x,
        y: enemy.y,
        motion: distance(world.player, enemy) < 86 ? "attack" : "walk",
        scale: .40,
        facing: enemy.facing,
        hp: enemy.hp,
        maxHp: enemy.maxHp,
      });
    }
    if (world.boss && !world.boss.dead) {
      actors.push({
        id: `boss_${String(state.chapterIndex + 1).padStart(2, "0")}`,
        x: world.boss.x,
        y: world.boss.y,
        motion: distance(world.player, world.boss) < 110 ? "attack" : "walk",
        scale: .58,
        facing: world.boss.facing,
        hp: world.boss.hp,
        maxHp: world.boss.maxHp,
        label: chapter.boss,
      });
    }
    const player = world.player;
    actors.push({
      id: "you",
      x: player.x,
      y: player.y,
      motion: player.hurtFx > 0 ? "hurt" : player.attackFx > 0 ? "attack" : Math.hypot(player.vx, player.vy) > .1 ? "walk" : "idle",
      scale: .48,
      facing: player.facing,
    });
    actors.sort((a, b) => a.y - b.y);
    for (const actor of actors) {
      drawActor(actor.id, actor.x, actor.y, actor.motion, actor.scale, actor.facing, actor.hp, actor.maxHp, actor.label);
    }

    if (player.attackFx > 0) {
      ctx.save();
      ctx.translate(player.x, player.y - 70);
      ctx.scale(player.facing, 1);
      ctx.strokeStyle = `rgba(238,219,164,${Math.min(1, player.attackFx * 5)})`;
      ctx.lineWidth = 7;
      ctx.beginPath();
      ctx.arc(0, 0, selected("eagle") ? 150 : 115, -1.05, .95);
      ctx.stroke();
      ctx.restore();
    }
  }

  function drawVignette() {
    const gradient = ctx.createRadialGradient(640, 350, 190, 640, 350, 720);
    gradient.addColorStop(0, "rgba(0,0,0,0)");
    gradient.addColorStop(1, "rgba(0,0,0,.48)");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, 1280, 720);
  }

  function render() {
    drawCover(imageFromCache(currentBackground));
    drawParticles();
    if (state.screen === "explore") drawWorld();
    drawVignette();
  }

  function loop(now) {
    const delta = Math.min(.034, Math.max(0, (now - lastTime) / 1000));
    lastTime = now;
    elapsed += delta;
    update(delta);
    render();
    requestAnimationFrame(loop);
  }

  function setupJoystick() {
    const base = $("joystick");
    const knob = $("joystick-knob");
    const update = (event) => {
      const rect = base.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;
      let x = event.clientX - centerX;
      let y = event.clientY - centerY;
      const radius = rect.width * .31;
      const length = Math.hypot(x, y);
      if (length > radius) {
        x = (x / length) * radius;
        y = (y / length) * radius;
      }
      joystick.x = x / radius;
      joystick.y = y / radius;
      knob.style.transform = `translate(calc(-50% + ${x}px), calc(-50% + ${y}px))`;
    };
    const reset = (event) => {
      if (joystick.pointerId !== null && event.pointerId !== joystick.pointerId) return;
      joystick.pointerId = null;
      joystick.x = 0;
      joystick.y = 0;
      knob.style.transform = "translate(-50%, -50%)";
    };
    base.addEventListener("pointerdown", (event) => {
      event.preventDefault();
      joystick.pointerId = event.pointerId;
      base.setPointerCapture(event.pointerId);
      update(event);
    });
    base.addEventListener("pointermove", (event) => {
      if (event.pointerId === joystick.pointerId) update(event);
    });
    base.addEventListener("pointerup", reset);
    base.addEventListener("pointercancel", reset);
  }

  function bindControls() {
    setupJoystick();
    $("attack-button").addEventListener("pointerdown", (event) => { event.preventDefault(); attack(); });
    $("dash-button").addEventListener("pointerdown", (event) => { event.preventDefault(); dash(); });
    $("burst-button").addEventListener("pointerdown", (event) => { event.preventDefault(); burst(); });
    $("interact-button").addEventListener("pointerdown", (event) => { event.preventDefault(); interact(); });
    $("hud-toggle").addEventListener("click", () => {
      hudVisible = !hudVisible;
      missions.classList.toggle("hidden", !hudVisible);
      hud.style.opacity = hudVisible ? "1" : ".32";
    });
    document.addEventListener("keydown", (event) => {
      const key = event.key.toLowerCase();
      keys.add(key);
      if ([" ", "j"].includes(key)) {
        event.preventDefault();
        attack();
      } else if (["shift", "k"].includes(key)) dash();
      else if (key === "q") burst();
      else if (key === "e") interact();
      else if (key === "tab") {
        event.preventDefault();
        $("hud-toggle").click();
      }
    });
    document.addEventListener("keyup", (event) => keys.delete(event.key.toLowerCase()));
    document.addEventListener("contextmenu", (event) => event.preventDefault());
  }

  async function init() {
    bindControls();
    loading.classList.remove("hidden");
    try {
      const response = await fetch("content.json", { cache: "no-cache" });
      if (!response.ok) throw new Error(`内容数据 ${response.status}`);
      content = await response.json();
      await loadBundle(["assets/backgrounds/cover.webp"], "正在展开轻量画卷");
      showTitle();
      requestAnimationFrame(loop);
      if ("serviceWorker" in navigator && location.protocol === "https:") {
        navigator.serviceWorker.register("service-worker.js").catch(() => {});
      }
    } catch (error) {
      loading.classList.add("hidden");
      setPanel(`
        <article class="panel-card title-card">
          <div class="eyebrow">画卷未能展开</div>
          <h1>连接中断</h1>
          <p>${escapeHtml(error.message || "请检查网络后重试")}</p>
          <button class="primary-button" onclick="location.reload()" type="button">重新加载</button>
        </article>
      `);
    }
  }

  init();
})();
