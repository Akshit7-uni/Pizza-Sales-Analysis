This directory consists of all the files and folders of the project.

#include <bits/stdc++.h>
#include "json.hpp" // nlohmann/json single header

using json = nlohmann::json;
using namespace std;

int main() {
    // ---------- Step 0: Load categories.json ----------
    ifstream catFile("data/categories.json");
    json catJson;
    catFile >> catJson;

    // parent -> list of direct children
    unordered_map<string, vector<string>> children;
    unordered_set<string> allCategoryIds;

    for (auto& c : catJson["categories"]) {
        string id = c["category_id"];
        allCategoryIds.insert(id);
        if (!c["parent_id"].is_null()) {
            string parent = c["parent_id"];
            children[parent].push_back(id);
        }
    }

    // ---------- Step 1 helper: collect a category + all descendants ----------
    auto collectDescendants = [&](const string& rootId) -> unordered_set<string> {
        unordered_set<string> included;
        if (!allCategoryIds.count(rootId)) return included; // doesn't exist -> empty

        queue<string> q;
        q.push(rootId);
        included.insert(rootId);
        while (!q.empty()) {
            string cur = q.front(); q.pop();
            if (children.count(cur)) {
                for (auto& child : children[cur]) {
                    if (!included.count(child)) {
                        included.insert(child);
                        q.push(child);
                    }
                }
            }
        }
        return included;
    };

    // ---------- Load products.jsonl ----------
    struct Product {
        string product_id;
        string name;
        string category_id;
        string region;
        double popularity_score;
        json raw; // keep original fields to output cleanly
    };

    vector<Product> products;
    {
        ifstream pf("data/products.jsonl");
        string line;
        while (getline(pf, line)) {
            if (line.empty()) continue;
            json p = json::parse(line);
            Product prod;
            prod.product_id = p["product_id"];
            prod.name = p.value("name", "");
            prod.category_id = p["category_id"];
            prod.region = p["region"];
            prod.popularity_score = p["popularity_score"];
            prod.raw = p;
            products.push_back(prod);
        }
    }

    // Index products by category for faster filtering
    unordered_map<string, vector<int>> productsByCategory;
    for (int i = 0; i < (int)products.size(); i++) {
        productsByCategory[products[i].category_id].push_back(i);
    }

    // ---------- Load requests.jsonl and process ----------
    json resultsArray = json::array();
    {
        ifstream rf("data/requests.jsonl");
        string line;
        while (getline(rf, line)) {
            if (line.empty()) continue;
            json req = json::parse(line);

            string query_id = req["query_id"];
            string category_id = req["category_id"];
            string region = req["region"];
            int max_results = req.value("max_results", 5);

            // Step 1: included categories
            unordered_set<string> included = collectDescendants(category_id);

            // Step 2: filter eligible products (category match + exact region match)
            vector<int> eligible;
            for (auto& catId : included) {
                if (productsByCategory.count(catId)) {
                    for (int idx : productsByCategory[catId]) {
                        if (products[idx].region == region) {
                            eligible.push_back(idx);
                        }
                    }
                }
            }

            int matched_count = (int)eligible.size();

            // Step 3: sort by popularity desc, then product_id asc
            sort(eligible.begin(), eligible.end(), [&](int a, int b) {
                if (products[a].popularity_score != products[b].popularity_score)
                    return products[a].popularity_score > products[b].popularity_score;
                return products[a].product_id < products[b].product_id;
            });

            if ((int)eligible.size() > max_results) {
                eligible.resize(max_results);
            }

            json outProducts = json::array();
            for (int idx : eligible) {
                outProducts.push_back(products[idx].raw);
            }

            json outObj;
            outObj["query_id"] = query_id;
            outObj["matched_count"] = matched_count;
            outObj["products"] = outProducts;

            resultsArray.push_back(outObj);
        }
    }

    // ---------- Write results.json ----------
    ofstream outFile("data/results.json");
    outFile << resultsArray.dump(2);
    outFile.close();

    return 0;
}