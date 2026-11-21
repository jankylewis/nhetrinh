// nhetrinh storybooks: the page menu, BACK / NEXT, and the note a clicked diagram node opens.
// A page sets <body data-page="design/02_components.html" data-root="../">; its notes are one JSON object in
// <script type="application/json" id="notes">: { "key": {"title": "...", "body": "<p>...</p>", "files": "..."} }.
const PAGES = [
  ["_index.html", "HOME"],
  ["design/_01_must_haves.html", "01 · MUST-HAVES"],
  ["design/02_components.html", "02 · COMPONENTS"],
  ["design/03_code_map.html", "03 · CODE MAP"],
  ["design/04_rules.html", "04 · DESIGN RULES"],
  ["runtime/_05_processes.html", "05 · PROCESSES"],
  ["runtime/06_page_load.html", "06 · ONE PAGE LOAD"],
  ["runtime/07_tab_life.html", "07 · A TAB'S LIFE"],
  ["runtime/08_disk.html", "08 · ON DISK"],
];

function buildMenu(root, page) {
  const header = document.createElement("header");
  header.className = "top";
  const nav = document.createElement("nav");
  nav.className = "menu box";
  nav.setAttribute("aria-label", "Storybook pages");
  for (const [href, name] of PAGES) {
    const link = document.createElement("a");
    link.href = root + href;
    link.textContent = name;
    link.className = href === page ? "tag" : "tag c";
    if (href === page) link.setAttribute("aria-current", "page");
    nav.appendChild(link);
  }
  header.appendChild(nav);
  document.querySelector("main").prepend(header);
}

function buildPager(root, page) {
  const at = PAGES.findIndex(([href]) => href === page);
  const pager = document.createElement("nav");
  pager.className = "pager";
  pager.setAttribute("aria-label", "Back and next");
  const back = PAGES[at - 1], next = PAGES[at + 1];
  pager.innerHTML = (back ? `<a href="${root + back[0]}">&#9664; ${back[1]}</a>` : "<span></span>") +
                    (next ? `<a href="${root + next[0]}">${next[1]} &#9654;</a>` : "<span></span>");
  document.querySelector("main").appendChild(pager);
}

function wireNotes() {
  const source = document.getElementById("notes");
  if (!source) return;
  const notes = JSON.parse(source.textContent);
  const dialog = document.createElement("dialog");
  dialog.className = "note";
  dialog.innerHTML = '<button class="close" aria-label="Close">&times;</button><div class="text"></div>';
  document.body.appendChild(dialog);
  dialog.querySelector(".close").addEventListener("click", () => dialog.close());
  dialog.addEventListener("click", (event) => { if (event.target === dialog) dialog.close(); });
  for (const node of document.querySelectorAll(".node[data-k]")) {
    const note = notes[node.dataset.k];
    if (!note) { node.removeAttribute("data-k"); continue; }
    node.setAttribute("role", "button");
    node.setAttribute("tabindex", "0");
    const open = () => {
      const files = note.files ? `<p class="files">Code: <code>${note.files}</code></p>` : "";
      dialog.querySelector(".text").innerHTML = `<h2>${note.title}</h2>${note.body}${files}`;
      dialog.showModal();
    };
    node.addEventListener("click", open);
    node.addEventListener("keydown", (event) => { if (event.key === "Enter" || event.key === " ") { event.preventDefault(); open(); } });
  }
}

document.addEventListener("DOMContentLoaded", () => {
  const root = document.body.dataset.root || "";
  const page = document.body.dataset.page;
  buildMenu(root, page);
  buildPager(root, page);
  wireNotes();
});
