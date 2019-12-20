var config = require('./core.js');
var prepareScenarios = require('./prepare_scenarios.js');

const scenarios = [
  {
    label: "home",
    path: "",
  },
  {
    label: "characters_icon_split",
    path: "users/3/characters?character_split=template&view=icons",
    selectors: ["#content"]
  },
  {
    label: "characters_list_combined",
    path: "users/3/characters?character_split=none&view=list",
    selectors: ["#content"]
  },
  {
    label: "galleries",
    path: "users/3/galleries",
    selectors: ["#content"]
  },
  {
    label: "gallery_show",
    path: "galleries/26",
    selectors: ["#content"]
  },
  {
    label: "post_edit",
    path: "posts/3/edit",
    selectors: ["#content"],
    delay: 1000
  },
  {
    label: "posts_unread",
    path: "posts/unread",
    selectors: ["#content"]
  },
  {
    label: "post_show_html",
    path: "posts/2?page=2&per_page=5&proofer-ignore",
    selectors: ["#content"],
    onReadyScript: 'puppet/paginatorHover.js',
    delay: 1000
  },
  {
    label: "report_daily",
    path: "reports/daily?day=2012-09-13",
    selectors: ["#content"]
  },
];

config.scenarios = scenarios.map(prepareScenarios);

module.exports = config;
