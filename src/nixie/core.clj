(ns nixie.core
  (:require
   [babashka.process :as process]
   [cheshire.core :as json]
   [clj-yaml.core :as yaml]
   [clojure.string :as string]
   [selmer.parser :as selmer]
   [babashka.fs :as fs])
  (:gen-class))

(defn parse-linguist [s]
  (->> s
       (re-find #"\{(.*)\}")
       second
       (#(string/split % #","))
       (map #(string/split % #"=>"))
       (map first)
       (map read-string)))

(defn linguist [dir]
  (->
   (process/process (format "ruby /Users/slim/slimslenderslacks/linguist/main.rb %s" dir)
                    {:out :string
                     :err :string})
   deref
   :out
   parse-linguist))

(def template (slurp "resources/template.flake.nix"))

(defn render [m]
  (selmer/render template m))

(comment
  (linguist "/Users/slim/slimslenderslacks/nanogpt/")
  (linguist "/Users/slim/docker/lsp")
  (linguist "/Users/slim/slimslenderslacks/linguist"))

(def trained {"Python" ["env" {:lets (string/join
                                      "\n" ["python = pkgs.python3;"
                                            "env = python.withPackages (ps: with ps; [numpy matplotlib cython scipy scikit-learn pytorch]);"])}]
              "Clojure" ["clojure"
                         "graalvmCEPackages.graalvm17-ce"
                         "clojure-lsp"
                         {:shell-hook "export GRAALVM_HOME=${pkgs.graalvmCEPackages.graalvm17-ce};\n"}]
              "Dockerfile" ["neovim" "temurin-bin"]
              "JavaScript" ["node2nix" "nodejs"]
              "Nix" ["rnix-lsp"]
              "Kotlin" ["temurin-bin"]
              "Java" ["temurin-bin"]
              "TypeScript" []
              "Ruby" ["ruby"]
              "Babashka" ["babashka" "temurin-bin"]
              "Slim" ["neovim"]})

(defn model [dir]
  (->> (linguist dir)
       (concat ["Slim"])
       (#(if (some #{"Java"} %) (concat % ["Babashka"]) %))
       (reduce (fn [agg feature] (concat agg (trained feature))) [])
       (into #{})
       (reduce (fn [m c]
                 (if (map? c)
                   (merge m c)
                   (update m :packages (fnil conj []) c))) {:description "nixie"})
       (#(merge % (when (not (contains? % :lets)) {:lets ""})))
       (#(merge % (when (not (contains? % :shell-hook)) {:shell-hook ""})))
       (#(update % :packages (fn [coll] (string/join " " coll))))
       (render)))

(defn -main [& args]
  (try
    (let [dir (fs/file (first args))
          nix-exp (model dir)]
      (println "... analyzing project " dir)
      (spit (fs/file dir "flake.nix") nix-exp)
      (spit (fs/file dir ".envrc") "use flake\n")
      (println "... wrote flake.nix")
      (System/exit 0))
    (catch Throwable t (println t) (System/exit 1))))

(comment
  (model "/Users/slim/slimslenderslacks/nanogpt")
  (model "/Users/slim/docker/lsp"))

(comment
  ;; 691
  (->
   (yaml/parse-string (slurp "resources/languages.yaml"))
   keys
   count)
  ;; 52836
  (->
   (json/parse-string (slurp "resources/nix-packages.json"))
   keys
   count)

  (def nix-packages
    (->
     (json/parse-string (slurp "resources/nix-packages.json"))
     keys))
  (require '[clojure.pprint :refer [pprint]])
  (spit "resources/packages.txt" (with-out-str (pprint nix-packages))))
