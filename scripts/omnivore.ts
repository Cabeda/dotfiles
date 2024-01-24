import { parseArgs } from "https://deno.land/std@0.207.0/cli/parse_args.ts";
interface Article {
    id: string;
    title: string;
    url: string;
    author?: string;
    wordsCount: number;
  }
  
  interface Edge {
    node: Article;
  }
  
  interface Response {
    data: {
      search: {
        edges: Edge[];
      };
    };
  }
  
  async function retrieveNewsletter(): Promise<Article[] | undefined> {
    const graphql = `query Search($after: String, $first: Int, $query: String) {
      search(first: $first, after: $after, query: $query) {
        ... on SearchSuccess {
          edges {
            node {
              id
              title
              url
              author
              wordsCount
            }
          }
        }
        ... on SearchError {
          errorCodes
        }
      }
    }
      `;
  
    if (!API_KEY) {
      console.error("Missing OMNIVORE_API_KEY");
      Deno.exit(1);
    }
  
    try {
      const response = await fetch("https://api-prod.omnivore.app/api/graphql", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          authorization: API_KEY,
        },
        body: JSON.stringify({
          query: graphql,
          variables: {
            query: "in:inbox label:newsletter",
            first: 100,
          },
        }),
      });
  
      const json: Response = await response.json();
  
      return json.data.search.edges.map((x) => x.node) as Article[];
    } catch (error) {
      console.error(error.message);
      throw new Error(error);
    }
  }
  
  function convertToMarkdown(articles: Article[]): string {
    const markdown = articles
      .map((article) => {
        const author = article.author ? ` by ${article.author}` : "";
        return `- [${article.title}${author}](${article.url})`;
      })
      .join("\n");
  
    return markdown;
  }
  
  async function archiveNewsletters(articles: Article[]): Promise<void> {
    console.log("Archiving articles with newsletter label");
  
    try {
      await articles.map((article) => {
        archiveNewsletter(article.id);
      });
    } catch (error) {
      console.error(error.message);
      throw new Error(error);
    }
    console.log("Articles archived");
  }
  
  async function getTotalArticles(query = "in:inbox no:label") {
    try {
      const graphql = `query Search($after: String, $first: Int, $query: String) {
        search(first: $first, after: $after, query: $query) {
          ... on SearchSuccess {
            pageInfo {
              totalCount
            }
          }
          ... on SearchError {
            errorCodes
          }
        }
      }    
      `;
  
      if (!API_KEY) {
        console.error("Missing OMNIVORE_API_KEY");
        Deno.exit(1);
      }
  
      const result = await fetch("https://api-prod.omnivore.app/api/graphql", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          authorization: API_KEY,
        },
        body: JSON.stringify({
          query: graphql,
          variables: {
            query,
          },
        }),
      });
  
      return await result.json();
    } catch (error) {
      console.error(error.message);
      throw new Error(error);
    }
  }
  
  async function archiveNewsletter(id: string): Promise<void> {
    try {
      const graphql = ` mutation SetLinkArchived($input: ArchiveLinkInput!) {
          setLinkArchived(input: $input) {
            ... on ArchiveLinkSuccess {
              linkId
              message
            }
            ... on ArchiveLinkError {
              message
              errorCodes
            }
          }
        }
      `;
  
      if (!API_KEY) {
        console.error("Missing OMNIVORE_API_KEY");
        Deno.exit(1);
      }
  
      const result = await fetch("https://api-prod.omnivore.app/api/graphql", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          authorization: API_KEY,
        },
        body: JSON.stringify({
          query: graphql,
          variables: {
            input: {
              archived: true,
              linkId: id,
            },
          },
        }),
      });
  
      console.log(await result.json());
    } catch (error) {
      console.error(error.message);
      throw new Error(error);
    }
  }
  
  const API_KEY = Deno.env.get("OMNIVORE_API_KEY");
  
  if (!API_KEY) {
    console.error("Missing OMNIVORE_API_KEY");
    Deno.exit(1);
  }
  const flags = parseArgs(Deno.args, {
    boolean: ["total", "archive"],
    string: ["query"],
  });


  
  if (flags.total) {
    console.log(flags.query);
    const total = await getTotalArticles(flags.query);
    console.log(`${total.data.search.pageInfo.totalCount} articles found`);
    Deno.exit(0);
  }
  
  const articles = await retrieveNewsletter();
  
  if (!articles) {
    console.error("No articles found");
    Deno.exit(1);
  }
  console.log(await convertToMarkdown(articles));
  
  if (flags.archive) {
    archiveNewsletters(articles);
  }
  