import { withMermaid } from "vitepress-plugin-mermaid";
import fs from "fs";
import path from "path";

// https://vitepress.dev/reference/site-config
export default withMermaid({
  title: "Viblog",
  description: "A VitePress Site",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [{ text: "Home", link: "/" }],

    sidebar: getArticlesSidebar(),

    socialLinks: [{ icon: "github", link: "https://github.com/gtnao/viblog" }],
  },
  base: "/viblog/",
  mermaid: { theme: "forest" },
  mermaidPlugin: { class: "mermaid my-class" },
  markdown: {
    math: true,
  },
});

function getArticlesSidebar() {
  const articlesPath = path.resolve(__dirname, "../articles");

  const subdirs = fs.readdirSync(articlesPath).filter((file) => {
    return fs.statSync(path.join(articlesPath, file)).isDirectory();
  });

  return subdirs.map((dir) => {
    const subdirPath = path.join(articlesPath, dir);
    const files = fs
      .readdirSync(subdirPath)
      .filter((file) => file.endsWith(".md"));

    const items = files.map((file) => {
      const name = path.basename(file, ".md");
      return {
        text: name,
        link: `/articles/${dir}/${name}`,
      };
    });

    return {
      text: dir,
      items: items,
      collapsible: true,
      collapsed: false,
    };
  });
}
