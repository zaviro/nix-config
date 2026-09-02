const GROUP = {
  PROXY: "节点选择",
  AUTO: "自动选择",
  FALLBACK: "故障转移",
  AI: "AI服务",
  AI_AUTO: "AI自动选择",
  GOOGLE: "Google服务",
  GOOGLE_FALLBACK: "Google故障转移",
};

const INFO_NODE_RE =
  "(?i)(剩余|流量|套餐|到期|官网|客服|traffic|expire|official|website|service)";
const AI_EXCLUDE_RE =
  INFO_NODE_RE + "|(?i)(香港|澳门|俄罗斯|hong kong|macau|macao|russia)";
// Google 与其他 AI 服务分别维护候选范围，避免调整 Gemini 时改变 Codex 选路。
// 港澳已在 Gemini Web 支持地区内；节点名称只用于排除明确不支持的俄罗斯。
const GOOGLE_EXCLUDE_RE =
  INFO_NODE_RE + "|(?i)(俄罗斯|russia)";

// 个人规则只表达本机策略；公共域名/IP 分类统一交给 MetaCubeX/meta-rules-dat。
const CUSTOM_RULES = [
  "DOMAIN-SUFFIX,wenku8.net,DIRECT",
];

// 关键域名即使规则集尚未下载也固定走同一 Google 出口；完整域名由 google 规则集补齐。
const GOOGLE_RULES = [
  "DOMAIN-SUFFIX,google.com," + GROUP.GOOGLE,
  "DOMAIN-SUFFIX,google.com.hk," + GROUP.GOOGLE,
  "DOMAIN-SUFFIX,google," + GROUP.GOOGLE,
  "DOMAIN-SUFFIX,goog," + GROUP.GOOGLE,
  "DOMAIN-SUFFIX,gstatic.com," + GROUP.GOOGLE,
  "DOMAIN-SUFFIX,googleapis.com," + GROUP.GOOGLE,
  "DOMAIN-SUFFIX,googleusercontent.com," + GROUP.GOOGLE,
  "DOMAIN-SUFFIX,gvt1.com," + GROUP.GOOGLE,
  "DOMAIN-SUFFIX,gvt2.com," + GROUP.GOOGLE,
  "DOMAIN-SUFFIX,gvt3.com," + GROUP.GOOGLE,
  "DOMAIN-SUFFIX,ggpht.com," + GROUP.GOOGLE,
  "DOMAIN-SUFFIX,googletagmanager.com," + GROUP.GOOGLE,
  "DOMAIN-SUFFIX,google-analytics.com," + GROUP.GOOGLE,
  "DOMAIN-REGEX,(^|\\.)google\\.[a-z.]+$," + GROUP.GOOGLE,
];

const META_RULESET_BASE =
  "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/";

function domainProvider(fileName) {
  return {
    type: "http",
    behavior: "domain",
    format: "mrs",
    interval: 86400,
    url: META_RULESET_BASE + "geosite/" + fileName + ".mrs",
    path: "./ruleset/" + fileName + ".mrs",
    proxy: GROUP.PROXY,
  };
}

function ipProvider(fileName) {
  return {
    type: "http",
    behavior: "ipcidr",
    format: "mrs",
    interval: 86400,
    url: META_RULESET_BASE + "geoip/" + fileName + ".mrs",
    path: "./ruleset/" + fileName + "_ip.mrs",
    proxy: GROUP.PROXY,
  };
}

const RULE_PROVIDERS = {
  ai: domainProvider("category-ai-!cn"),
  openai: domainProvider("openai"),
  google: domainProvider("google"),
  github: domainProvider("github"),
  telegram_domain: domainProvider("telegram"),
  telegram_ip: ipProvider("telegram"),
  cn_domain: domainProvider("cn"),
  cn_ip: ipProvider("cn"),
  not_cn_domain: domainProvider("geolocation-!cn"),
};

const HEALTH_CHECK = {
  url: "https://www.gstatic.com/generate_204",
  interval: 300,
  timeout: 5000,
  lazy: true,
  "max-failed-times": 3,
};

function healthGroup(name, type, excludeFilter, extra = {}) {
  return {
    name,
    type,
    "include-all": true,
    "exclude-filter": excludeFilter,
    ...HEALTH_CHECK,
    ...extra,
  };
}

const PROXY_GROUPS = [
  {
    name: GROUP.PROXY,
    type: "select",
    proxies: [GROUP.AUTO, GROUP.FALLBACK, "DIRECT"],
    "include-all": true,
    "exclude-filter": INFO_NODE_RE,
  },
  healthGroup(GROUP.AUTO, "url-test", INFO_NODE_RE, { tolerance: 80 }),
  healthGroup(GROUP.FALLBACK, "fallback", INFO_NODE_RE),
  {
    name: GROUP.AI,
    type: "select",
    proxies: [GROUP.AI_AUTO, GROUP.PROXY],
    "include-all": true,
    "exclude-filter": AI_EXCLUDE_RE,
  },
  healthGroup(GROUP.AI_AUTO, "url-test", AI_EXCLUDE_RE, { tolerance: 100 }),
  {
    name: GROUP.GOOGLE,
    type: "select",
    proxies: [GROUP.GOOGLE_FALLBACK],
    "include-all": true,
    "exclude-filter": GOOGLE_EXCLUDE_RE,
  },
  healthGroup(GROUP.GOOGLE_FALLBACK, "fallback", GOOGLE_EXCLUDE_RE),
];

const INFRA_RULES = [
  "DOMAIN,localhost,DIRECT",
  "DOMAIN-SUFFIX,local,DIRECT",
  "IP-CIDR,127.0.0.0/8,DIRECT,no-resolve",
  "IP-CIDR,10.0.0.0/8,DIRECT,no-resolve",
  "IP-CIDR,172.16.0.0/12,DIRECT,no-resolve",
  "IP-CIDR,192.168.0.0/16,DIRECT,no-resolve",
  "IP-CIDR,169.254.0.0/16,DIRECT,no-resolve",
  "IP-CIDR6,::1/128,DIRECT,no-resolve",
  "IP-CIDR6,fc00::/7,DIRECT,no-resolve",
  "IP-CIDR6,fe80::/10,DIRECT,no-resolve",
];

const MANAGED_RULES = INFRA_RULES.concat(
  CUSTOM_RULES,
  GOOGLE_RULES,
  [
    "RULE-SET,google," + GROUP.GOOGLE,
    "RULE-SET,ai," + GROUP.AI,
    "RULE-SET,openai," + GROUP.AI,
    "RULE-SET,github," + GROUP.PROXY,
    "RULE-SET,telegram_domain," + GROUP.PROXY,
    "RULE-SET,telegram_ip," + GROUP.PROXY + ",no-resolve",
    "RULE-SET,cn_domain,DIRECT",
    "RULE-SET,not_cn_domain," + GROUP.PROXY,
    "RULE-SET,cn_ip,DIRECT",
    "MATCH," + GROUP.PROXY,
  ]
);

function main(config, profileName) {
  const proxyCount = Array.isArray(config.proxies) ? config.proxies.length : 0;
  const providers = config["proxy-providers"];
  const providerCount =
    providers && typeof providers === "object"
      ? Object.keys(providers).length
      : 0;

  if (proxyCount === 0 && providerCount === 0) {
    throw new Error(
      "当前订阅没有 proxies 或 proxy-providers，无法建立代理组"
    );
  }

  config.mode = "rule";
  config["proxy-groups"] = PROXY_GROUPS;
  config["rule-providers"] = RULE_PROVIDERS;
  config.rules = MANAGED_RULES;
  return config;
}
