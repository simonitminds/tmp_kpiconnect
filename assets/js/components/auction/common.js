import Spot from './spot/spot';
import Term from './term/term';

export function componentsForAuction(type) {
  switch (type) {
    case 'spot':
      return Spot;
    case 'forward_fixed':
      return Term;
    case 'formula_related':
      return null;
  }
}
