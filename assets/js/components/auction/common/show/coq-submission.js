import React from 'react';
import _ from 'lodash';

class COQSubmission extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      uploading: false
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.auctionPayload !== prevProps.auctionPayload) {
      this.setState({
        uploading: false
      })
    }
  }

  submitForm(ev) {
    ev.preventDefault();
    this.setState({ uploading: true });
    const form = ev.target;
    const data = new FormData(form);
    const fuelId = data.get("fuelId");
    const coq = data.get("coq");
    const { addCOQ, auctionPayload, supplierId } = this.props;
    const { auction } = auctionPayload;
    addCOQ(auction.id, supplierId, fuelId, coq);
    document.querySelector(`#coq-${fuelId}`).value = null;
  }

  render() {
    const { auctionPayload, deleteCOQ, supplierId } = this.props;
    const auction = auctionPayload.auction;
    const supplierCOQs = auction.auction_supplier_coqs;
    const fuels = auction.fuels;
    const auctionState = auctionPayload.status;
    const validAuctionState = auctionState === 'pending' || auctionState === 'open';

    const renderCOQComponent = () => {
      if (window.isAdmin || validAuctionState || (!validAuctionState && supplierCOQs.length != 0) ) {
        return (
          <div className="box has-margin-bottom-md has-padding-bottom-none">
            <div className="box__subsection has-padding-bottom-none">
              <h3 className="box__header">COQs</h3>
              <div className="qa-coqs">
                {fuels.map(renderCOQ)}
              </div>
            </div>
          </div>
        )
      }
    }

    const renderCOQ = (fuel) => {
      return (
        <div className={`qa-coq-${fuel.id}`} key={fuel.id}>
          {fuel.name}
          {renderCOQLink(auction.id, fuel.id, supplierId, supplierCOQs)}
          {renderCOQForm(fuel)}
        </div>
      );
    };

    const renderCOQForm = (fuel) => {
      if (window.isAdmin || validAuctionState) {
        return (
          <form onSubmit={this.submitForm.bind(this)}>
            <input name="coq" type="file" id={`coq-${fuel.id}`} />
            <input name="fuelId" hidden={true} defaultValue={fuel.id} ref={(ref) => { this.fuelId = ref; }} />
            {renderSubmitButton()}
          </form>
        )
      }
    }

    const renderCOQLink = (auctionId, fuelId, supplierId, supplierCOQs) => {
      const supplierCOQ = _.find(supplierCOQs, { 'fuel_id': fuelId, 'supplier_id': parseInt(supplierId) });

      if (supplierCOQ) {
        return (
          <div>
            <a href={`/supplier_coq/${supplierCOQ.id}`} target="_blank">View COQ</a>
            { (window.isAdmin || validAuctionState) ? <a className="button is-danger has-margin-top-sm" onClick={(e) => deleteCOQ(supplierCOQ.id)}>Delete</a> : "" }
          </div>
        )
      }
    }

    const renderSubmitButton = () => {
      if (this.state.uploading) {
        return (<button disabled={true} className="button is-primary has-margin-top-sm">Processing...</button>)
      } else {
        return (<button type="submit" className="button is-primary has-margin-top-sm">Upload COQ</button>)
      }
    }

    return (
      <div>
        { renderCOQComponent() }
      </div>
    );
  }
}

export default COQSubmission;
