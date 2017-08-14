function numparams{S,P,O<:FullPolyOrder}(model::IdentificationToolbox.PolyModel{S,O,P}, options::IdOptions=IdOptions())
  na,nb,nf,nc,nd,nk = IdentificationToolbox.orders(model)
  ny,nu = model.ny, model.nu
  nbf   = max(nb+nk[1], nf)
  ndc   = max(nd, nc)
  ncda  = max(nc, nd+na)
  m     = ny^2*(na+nf+nc+nd)+nu*ny*nb
  mi    = (ndc+nbf+ncda)*ny
  nump = options.estimate_initial ? m+mi : m
  return nump
end
