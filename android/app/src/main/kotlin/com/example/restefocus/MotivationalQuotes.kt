package com.example.restefocus

/**
 * Citations affichées sous le défi (ou le décompte de pause) du Math Gate
 * natif. Liste statique en mémoire — aucun coût de performance, cohérent
 * avec l'overlay qui doit s'afficher instantanément (voir MathGateActivity).
 * Copie indépendante de lib/core/constants.dart#mathGateQuotes (même
 * contenu), le natif ne dépendant pas du moteur Flutter.
 */
object MotivationalQuotes {
    val ALL = listOf(
        "« La logique vous mènera d'un point A à un point B. L'imagination vous mènera partout. » — Albert Einstein",
        "« Il n'y a pas de voie royale vers la géométrie. » — Euclide",
        "« Ce que nous savons est une goutte d'eau, ce que nous ignorons est un océan. » — Isaac Newton",
        "« Le hasard ne favorise que les esprits préparés. » — Louis Pasteur",
        "« La nature ne fait rien en vain. » — Aristote",
        "« Donnez-moi un point d'appui et un levier, et je soulèverai le monde. » — Archimède",
        "« Le cœur a ses raisons que la raison ne connaît point. » — Blaise Pascal",
        "« Je pense, donc je suis. » — René Descartes",
        "« Dans la science, il n'y a jamais eu de grand pas fait par un seul homme. » — Marie Curie",
        "« Il est impossible d'être un mathématicien sans être un poète dans l'âme. » — Sofia Kovalevskaya",
        "« Je préfère les questions qui ne peuvent pas être répondues aux réponses qui ne peuvent pas être questionnées. » — Richard Feynman",
        "« C'est la poésie de la logique. » — Ada Lovelace, à propos du calcul",
        "« L'algèbre est la clé qui ouvre les mathématiques modernes. » — Al-Khwarizmi",
        "« L'Afrique n'est pas un pays, c'est un continent d'inventeurs. » — Cheikh Anta Diop",
        "« On ne peut pas résoudre un problème avec le même niveau de pensée qui l'a créé. » — Albert Einstein",
        "« La persévérance est la clé du succès. » — Nelson Mandela",
        "« Il vaut mieux allumer une bougie que maudire l'obscurité. » — Confucius",
        "« La discipline est le pont entre les objectifs et les résultats. » — Jim Rohn",
        "« Chaque calcul résolu est une distraction en moins. »",
        "« Le génie, c'est 1% d'inspiration et 99% de transpiration. » — Thomas Edison",
        "« On n'apprend pas en restant passif. On apprend en résolvant. »",
        "« La vitesse ne compte pas si tu vas dans la mauvaise direction. »",
    )

    fun random(): String = ALL.random()
}
