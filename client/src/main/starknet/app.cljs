(ns starknet.app
    (:require 
        [reagent.core :as r]
        [reagent.dom :as rdom])
    (:require ["@starknet-react/core" :refer [useStarknet, StarknetProvider, InjectedConnector]]))

(defn init []
    (println "Hello, world bobobob!"))

(defn app []
    [:> StarknetProvider]
    [:b "Hello World!"])

(println "hi" useStarknet InjectedConnector StarknetProvider)

(defn main []
    (let [app-node (.getElementById js/document "root")]
        (rdom/render [app] app-node)))
       
(main)