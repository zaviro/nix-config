const GROUP = {
  PROXY: "节点选择",
  AUTO: "自动选择",
  FALLBACK: "故障转移",
  AI: "AI服务",
  AI_AUTO: "AI自动选择",
};

const INFO_NODE_RE =
  "(?i)(剩余|流量|套餐|到期|官网|客服|traffic|expire|official|website|service)";
const AI_EXCLUDE_RE =
  INFO_NODE_RE + "|(?i)(香港|澳门|俄罗斯|hong kong|macau|macao|russia)";

// 个人规则放在公共规则集之前；wenku8.net 及其子域名始终直连。
const CUSTOM_RULES = [
  "DOMAIN-SUFFIX,wenku8.net,DIRECT",
];

// Tailscale 控制面与 DERP 直连，避免其流量经代理往返；
// tailnet 网段已由 merge.yaml 的 route-exclude-address 排除出 TUN。
const TAILSCALE_RULES = [
  "DOMAIN-SUFFIX,tailscale.com,DIRECT",
  "DOMAIN-SUFFIX,tailscale.io,DIRECT",
  "DOMAIN-SUFFIX,ts.net,DIRECT",
  "IP-CIDR,192.200.0.0/16,DIRECT,no-resolve",
  "IP-CIDR6,fd7a:115c:a1e0::/48,DIRECT,no-resolve",
];

const RULESET_BASE =
  "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/";

function domainProvider(fileName) {
  return {
    type: "http",
    behavior: "domain",
    format: "mrs",
    interval: 86400,
    url: RULESET_BASE + "geosite/" + fileName + ".mrs",
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
    url: RULESET_BASE + "geoip/" + fileName + ".mrs",
    path: "./ruleset/" + fileName + "_ip.mrs",
    proxy: GROUP.PROXY,
  };
}

const RULE_PROVIDERS = {
  ai: domainProvider("category-ai-!cn"),
  openai: domainProvider("openai"),
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
  "IP-CIDR,100.64.0.0/10,DIRECT,no-resolve",
];

const MANAGED_RULES = INFRA_RULES.concat(TAILSCALE_RULES, CUSTOM_RULES, [
  "RULE-SET,ai," + GROUP.AI,
  "RULE-SET,openai," + GROUP.AI,
  "RULE-SET,github," + GROUP.PROXY,
  "RULE-SET,telegram_domain," + GROUP.PROXY,
  "RULE-SET,telegram_ip," + GROUP.PROXY + ",no-resolve",
  "RULE-SET,cn_domain,DIRECT",
  "RULE-SET,not_cn_domain," + GROUP.PROXY,
  "RULE-SET,cn_ip,DIRECT,no-resolve",
  "GEOIP,CN,DIRECT,no-resolve",
  "MATCH," + GROUP.PROXY,
]);

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

  const dns = (config.dns ??= {});
  const filter = dns["fake-ip-filter"] ?? [];
  dns["fake-ip-filter"] = [
    ...new Set([
      ...filter,
      "+.tailscale.com",
      "+.tailscale.io",
      "+.ts.net",
    ]),
  ];

  config.mode = "rule";
  config["proxy-groups"] = PROXY_GROUPS;
  config["rule-providers"] = RULE_PROVIDERS;
  config.rules = MANAGED_RULES;
  return config;
}
