make_node_motif <- function(out, .data) {
  class(out) <- c("node_motif", class(out))
  if(is_twomode(.data)) attr(out, "mode") <- node_is_mode(.data)
  if(is_labelled(.data)) attr(out, "dimnames")[[1]] <- node_names(.data)
  out
}

make_network_motif <- function(out, .data) {
  class(out) <- c("network_motif", class(out))
  attr(out, "mode") <- net_dims(.data)
  attr(out, "call") <- deparse(sys.calls())
  out
}

#' @export
print.node_motif <- function(x, ...,
                         n = 6,
                         digits = 3) {
  if (any(attr(x, "mode"))) {
    y <- as.data.frame(x[!attr(x, "mode"),])
    z <- as.data.frame(x[attr(x, "mode"),])
    if(!is.null(attr(x, "dimnames")[[1]])){
      y <- data.frame(names = attr(x, "dimnames")[[1]][!attr(x, "mode")], y)
      z <- data.frame(names = attr(x, "dimnames")[[1]][attr(x, "mode")], z)
    } 
    print(dplyr::tibble(y), n = n)
    print(dplyr::tibble(z), n = n)
  } else {
    if(!is.null(attr(x, "dimnames")[[1]])){
      x <- data.frame(names = attr(x, "dimnames")[[1]], x)
    } else x <- as.data.frame(x)
    print(dplyr::tibble(x), n = n)
  }
}


# summary(node_by_triad(mpn_elite_mex),
#         membership = node_regular_equivalence(mpn_elite_mex, "elbow"))
#' @export
summary.node_motif <- function(object, ...,
                                membership,
                                FUN = mean) {
  out <- t(sapply(unique(membership), function(x) {
    if (sum(membership==x)==1) object[membership==x,]
    else apply(object[membership == x, ], 2, FUN)
  }))
  rownames(out) <- paste("Block", unique(membership))
  dplyr::tibble(as.data.frame(out))
}

#' @export
print.network_motif <- function(x, ...) {
  names <- list(names(x))
  x <- as.numeric(x)
  mat <- matrix(x, dimnames = names)
  mat <- t(mat)
  out <- as.data.frame(mat)
  print(dplyr::tibble(out))
}

#' @export
summary.network_motif <- function(object, ...,
                               null = c("random","configuration"), 
                               times = 500) {
  null <- paste0("generate_", match.arg(null))
  callItems <- trimws(strsplit(unlist(attr(object, "call")), 
                               split = "\\(|\\)|,")[[1]])
  idFun <- which(grepl("net_by_", callItems))[1]
  fun <- callItems[idFun]
  dat <- callItems[idFun+1]
  nulls <- t(vapply(snet_progress_seq(times), function(r){
    suppressMessages(get(fun)(get(null)(get(dat))))
  }, FUN.VALUE = numeric(length(object))))
  out <- (object - colMeans(nulls))/apply(nulls, 2, stats::sd)
  out[is.nan(out)] <- 0
  out
}


