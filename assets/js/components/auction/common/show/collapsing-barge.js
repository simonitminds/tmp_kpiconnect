import React, { Component } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import PropTypes from 'prop-types';

// NOTE: Sourced from glennflanagan's react-collapsible component (https://github.com/glennflanagan/react-collapsible/blob/develop/src/Collapsible.js)

class CollapsingBarge extends Component {
  constructor(props) {
    super(props)

    // Bind class methods
    this.handleTriggerClick = this.handleTriggerClick.bind(this);
    this.handleTransitionEnd = this.handleTransitionEnd.bind(this);
    this.continueOpenCollapsible = this.continueOpenCollapsible.bind(this);

    // Defaults the dropdown to be closed
    if (props.open) {
      this.state = {
        isClosed: false,
        shouldSwitchAutoOnNextCycle: false,
        height: 'auto',
        transition: 'none',
        hasBeenOpened: true,
        overflow: props.overflowWhenOpen,
        inTransition: false,
      }
    } else {
      this.state = {
        isClosed: true,
        shouldSwitchAutoOnNextCycle: false,
        height: 0,
        transition: `height ${props.transitionTime}ms ${props.easing}, border-top-color 0ms ease-in 300ms`,
        hasBeenOpened: false,
        overflow: 'hidden',
        inTransition: false,
      }
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if(this.state.shouldOpenOnNextCycle){
      this.continueOpenCollapsible();
    }

    if (prevState.height === 'auto' && this.state.shouldSwitchAutoOnNextCycle === true) {
      window.setTimeout(() => { // Set small timeout to ensure a true re-render
        this.setState({
          height: 0,
          overflow: 'hidden',
          isClosed: true,
          shouldSwitchAutoOnNextCycle: false,
        });
      }, 50);
    }

    // If there has been a change in the open prop (controlled by accordion)
    if (prevProps.open !== this.props.open) {
      if(this.props.open === true) {
        this.openCollapsible();
        this.props.onOpening();
      } else {
        this.closeCollapsible();
        this.props.onClosing();
      }
    }
  }

  closeCollapsible() {
    this.setState({
      shouldSwitchAutoOnNextCycle: true,
      height: this.refs.inner.offsetHeight,
      transition: `height ${this.props.transitionTime}ms ${this.props.easing}, border-top-color 200ms ease-in`,
      inTransition: true,
    });
  }

  openCollapsible() {
    this.setState({
      inTransition: true,
      shouldOpenOnNextCycle: true,
    });
  }

  continueOpenCollapsible() {
    this.setState({
      height: this.refs.inner.offsetHeight,
      transition: `height ${this.props.transitionTime}ms ${this.props.easing}, border-top-color 100ms ease-in`,
      isClosed: false,
      hasBeenOpened: true,
      inTransition: true,
      shouldOpenOnNextCycle: false,
    });
  }

  handleTriggerClick(event) {
    event.preventDefault();

    if (this.props.triggerDisabled) {
      return
    }

    if (this.props.handleTriggerClick) {
      this.props.handleTriggerClick(this.props.accordionPosition);
    } else {
      if (this.state.isClosed === true) {
        this.openCollapsible();
        this.props.onOpening();
      } else {
        this.closeCollapsible();
        this.props.onClosing();
      }
    }
  }

  renderNonClickableTriggerElement() {
    if (this.props.triggerSibling && typeof this.props.triggerSibling === 'string') {
      return (
        <span className={`${this.props.classParentString}__trigger-sibling`}>{this.props.triggerSibling}</span>
      )
    } else if(this.props.triggerSibling) {
      return <this.props.triggerSibling />
    }

    return null;
  }

  handleTransitionEnd() {
    // Switch to height auto to make the container responsive
    if (!this.state.isClosed) {
      this.setState({ height: 'auto', overflow: this.props.overflowWhenOpen, inTransition: false });
      this.props.onOpen();
    } else {
      this.setState({ inTransition: false });
      this.props.onClose();
    }
  }

  render() {
    var dropdownStyle = {
      height: this.state.height,
      WebkitTransition: this.state.transition,
      msTransition: this.state.transition,
      transition: this.state.transition,
      overflow: this.state.overflow,
    }

    var openClass = this.state.isClosed ? 'is-closed' : 'is-open';
    var disabledClass = this.props.triggerDisabled ? 'is-disabled' : '';

    //If user wants different text when tray is open
    var trigger = (this.state.isClosed === false) && (this.props.triggerWhenOpen !== undefined)
                  ? this.props.triggerWhenOpen
                  : this.props.trigger;

    // Don't render children until the first opening of the Collapsible if lazy rendering is enabled
    var children = this.props.lazyRender
      && !this.state.hasBeenOpened
      && this.state.isClosed
      && !this.state.inTransition ? null : this.props.children;

    // Construct CSS classes strings
    const triggerClassString = `${this.props.classParentString}__trigger ${openClass} ${disabledClass} ${
      this.state.isClosed ? this.props.triggerClassName : this.props.triggerOpenedClassName
    }`;
    const parentClassString = `${this.props.classParentString} ${
      this.state.isClosed ? this.props.className : this.props.openedClassName
    } ${openClass}`;
    const outerClassString = `${this.props.classParentString}__contentOuter ${this.props.contentOuterClassName}`;
    const innerClassString = `${this.props.classParentString}__contentInner ${this.props.contentInnerClassName}`;

    // Barging Data
    const barge = this.props.barge;
    const supplierId = this.props.supplierId;
    const isBuyer = this.props.isBuyer;
    const isAdmin = window.isAdmin;
    const isImpersonating = window.isImpersonating;
    const approveBargeForm = this.props.approveBargeForm;
    const rejectBargeForm = this.props.rejectBargeForm;
    const submitBargeForm = this.props.submitBargeForm;
    const unsubmitBargeForm = this.props.unsubmitBargeForm;
    const auction = this.props.auction;
    const bargeStatus = (this.props.bargeStatus || 'available').toLowerCase();
    const auctionState = this.props.auctionState;

    const approvalStatusIcon = () => {
      if (bargeStatus == 'pending') { return `question-circle` }
      else if (bargeStatus == 'approved') { return `check-circle` }
      else if (bargeStatus == 'rejected') {return `times-circle`}
      else {return `ban`}
    };

    const bargeAction = () => {
      if(isBuyer) {
        switch(bargeStatus) {
          case 'pending':
            return (
              <div className="collapsing-barge__barge__button buttons has-addons has-margin-bottom-none">
                <button onClick={ approveBargeForm.bind(this, auction.id, barge.id, supplierId) } className={ `button is-small is-success qa-auction-barge-approve-${barge.id}` }><FontAwesomeIcon icon="check" /><span>Approve</span></button>
                <button onClick={ rejectBargeForm.bind(this, auction.id, barge.id, supplierId) } className={ `button is-small is-danger qa-auction-barge-reject-${barge.id}` }><FontAwesomeIcon icon="times" /><span>Reject</span></button>
              </div>)
          case 'approved':
            return (
              <div className="collapsing-barge__barge__button collapsing-barge__barge__button--toggle">
                <button onClick={ rejectBargeForm.bind(this, auction.id, barge.id, supplierId) } className={ `button is-small is-success qa-auction-barge-reject-${barge.id}` }><span>Approved</span></button>
              </div>)
          case 'rejected':
            return (
              <div className="collapsing-barge__barge__button collapsing-barge__barge__button--toggle">
                <button onClick={ approveBargeForm.bind(this, auction.id, barge.id, supplierId) } className={ `button is-small is-danger qa-auction-barge-approve-${barge.id}` }><span>Rejected</span></button>
              </div>)
        }
      }
      else {
        switch(bargeStatus) {
          case 'available':
            return (
              <div className="collapsing-barge__barge__button">
                <button onClick={ submitBargeForm.bind(this, auction.id, barge.id) } className={ `button is-small is-primary qa-auction-barge-submit-${barge.id}` }>Submit</button>
              </div>)
          default:
            return (
              <div className="collapsing-barge__barge__button collapsing-barge__barge__button--unsubmit">
                <a onClick={ unsubmitBargeForm.bind(this, auction.id, barge.id) } className={ `qa-auction-barge-unsubmit-${barge.id}` }><FontAwesomeIcon icon="times" /></a>
              </div>)
        }
      }
    };

    return(
      <section className={`qa-barge-${barge.id} qa-barge-status-${bargeStatus} ${parentClassString.trim()}`}>
        <div className="container is-fullhd">
          <div className={`content has-gray-lighter${bargeStatus != 'available' ? ' submitted' : ''}`}>
            <h2
              className={"qa-barge-header " + triggerClassString.trim()}
              onClick={this.handleTriggerClick}
              style={this.props.triggerStyle && this.props.triggerStyle}
            >
              <span className="collapsible-section__toggle-icon"><FontAwesomeIcon icon={this.state.isClosed ? "angle-right" : "angle-down"} /></span>
              <span className={`collapsible-section__category-icon collapsible-section__category-icon--${bargeStatus}`}><FontAwesomeIcon icon={approvalStatusIcon()} /></span>
              <span className="collapsible-section__title">{trigger}</span>
           </h2>
           { (auctionState == 'expired' || auctionState == 'closed' || auctionState == 'canceled' || (isAdmin && !isImpersonating)) ? "" : bargeAction() }
          </div>
        </div>

        {this.renderNonClickableTriggerElement()}

        <div className="container is-fullhd"
          ref="outer"
          style={dropdownStyle}
          onTransitionEnd={this.handleTransitionEnd}
        >
          <div className="content has-gray-lighter"
            ref="inner"
        >
            <div className="collapsing-barge__barge__header">
              <div className="collapsing-barge__barge__content">
                <p><strong>Port</strong> {barge.port}</p>
                <p><strong>Approved for</strong> (Approved for)</p>
                <p><strong>Last SIRE Inspection</strong> ({barge.sire_inspection_date})</p>
              </div>
            </div>
          </div>
        </div>
      </section>
    );
  }
}

CollapsingBarge.propTypes = {
  transitionTime: PropTypes.number,
  easing: PropTypes.string,
  open: PropTypes.bool,
  classParentString: PropTypes.string,
  openedClassName: PropTypes.string,
  triggerStyle: PropTypes.object,
  triggerClassName: PropTypes.string,
  triggerOpenedClassName: PropTypes.string,
  contentOuterClassName: PropTypes.string,
  contentInnerClassName: PropTypes.string,
  accordionPosition: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  handleTriggerClick: PropTypes.func,
  onOpen: PropTypes.func,
  onClose: PropTypes.func,
  onOpening: PropTypes.func,
  onClosing: PropTypes.func,
  trigger: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.element
  ]),
  triggerWhenOpen:PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.element
  ]),
  triggerDisabled: PropTypes.bool,
  lazyRender: PropTypes.bool,
  overflowWhenOpen: PropTypes.oneOf([
    'hidden',
    'visible',
    'auto',
    'scroll',
    'inherit',
    'initial',
    'unset',
  ]),
  triggerSibling: PropTypes.oneOfType([
    PropTypes.element,
    PropTypes.func,
  ]),
}

CollapsingBarge.defaultProps = {
  transitionTime: 300,
  easing: 'ease-in',
  open: false,
  classParentString: 'Collapsible',
  triggerDisabled: false,
  lazyRender: false,
  overflowWhenOpen: 'hidden',
  openedClassName: '',
  triggerStyle: null,
  triggerClassName: '',
  triggerOpenedClassName: '',
  contentOuterClassName: '',
  contentInnerClassName: '',
  className: '',
  triggerSibling: null,
  onOpen: () => {},
  onClose: () => {},
  onOpening: () => {},
  onClosing: () => {},
};

export default CollapsingBarge;
